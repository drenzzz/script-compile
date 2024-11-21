#!/bin/bash
#
# Copyright (C) 2024 Drenzzz
#

# init
WORK_DIR=$(pwd)
ANYKERNEL="${WORK_DIR}/anykernel"
ANYKERNEL_REPO="https://github.com/drenzzz/AnyKernel3.git" 
ANYKERNEL_BRANCH="garnet"
KERNEL_DIR="garnet"

# VERSIONING
KSU="ksu"
NKSU="non-ksu"
REL="v2"
KERNEL="Shorekeeper-$REL-$NKSU"
ZIPNAME=$KERNEL.zip
KERN_IMG=$WORK_DIR/out/garnet/arch/arm64/boot/Image.gz

# setup telegram
CHATIDQ="-1001865504975"
CHATID="-1001865504975" # Group/channel chatid (use rose/userbot to get it)
TELEGRAM_TOKEN="7869677269:AAF-4G93D7SO9MlAZNcVo_f59VtTjVEsTxc" # Get from botfather

# setup color
red='\033[0;31m'
green='\e[0;32m'
white='\033[0m'
yellow='\033[0;33m'

function clean() {
    echo -e "\n"
    echo -e "$red << cleaning up >> \n$white"
    echo -e "\n"
    rm -rf ${ANYKERNEL}
    rm -rf out
}

function pack_kernel() {
    echo -e "\n"
    echo -e "$yellow << packing kernel >> \n$white"
    echo -e "\n"

    TELEGRAM_FOLDER="${HOME}"/workspaces/telegram
    if ! [ -d "${TELEGRAM_FOLDER}" ]; then
        git clone https://github.com/drenzzz/telegram.sh/ "${TELEGRAM_FOLDER}"
    fi

    TELEGRAM="${TELEGRAM_FOLDER}"/telegram

    git clone "$ANYKERNEL_REPO" -b "$ANYKERNEL_BRANCH" "$ANYKERNEL"

    cp $KERN_IMG $ANYKERNEL/Image.gz
    cd $ANYKERNEL || exit
    zip -r9 $ZIPNAME ./*

    END_TIME=$(date +%s)
    DIFF=$((END_TIME - START_TIME))

    DATE_BUILD=$(date +"%A, %B %d, %Y | %H:%M:%S ETC")
    DOCKER_OS=$(lsb_release -d | cut -f2- || uname -o)
    KERNEL_VERSION=$(make -s kernelversion -C "$WORK_DIR/garnet" 2>/dev/null)

    CLANG_INFO=$("$WORK_DIR/prebuilts-master/clang/host/linux-x86/clang-19/bin/clang" --version)
    CLANG_VERSION=$("$WORK_DIR/prebuilts-master/clang/host/linux-x86/clang-19/bin/clang" --version | grep -oP 'version \K[^\s]+')
    CLANG_URL="https://android.googlesource.com/toolchain/llvm-project"
    CLANG_COMMIT=$(echo "$CLANG_INFO" | grep -oP 'based on r\K[0-9a-f]+') # Ambil commit hash

    MD5_CHECKSUM=$(md5sum "$ZIPNAME" | awk '{ print $1 }')

    tg_post_build() {
        $TELEGRAM -f "$1" -t $TELEGRAM_TOKEN -c $CHATIDQ -T "Build Summary
Build took : \`$((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)\`
Date build : \`$DATE_BUILD\`
Docker OS : \`$DOCKER_OS\`
Kernel Version : \`$KERNEL_VERSION\`
Clang version : \`$CLANG_VERSION ($CLANG_URL $CLANG_COMMIT)\`
MD5 Checksum : \`$MD5_CHECKSUM\`"
    }

    tg_post_build "$ZIPNAME"

    echo -e "\n"
    echo -e "$green << kernel uploaded to telegram >>"
    echo -e "\n"
}


function build_kernel() {
    echo -e "\n"
    echo -e "$yellow << building kernel >> \n$white"
    echo -e "\n"

    # Mulai pencatatan waktu
    START_TIME=$(date +%s)
    
    cd $WORK_DIR
    LTO=thin BUILD_CONFIG=garnet/build.config.gki.custom build/build.sh 2>&1 | tee build.log && cat build.log | nc termbin.com 9999

    BUILD_STATUS=$?  

    if [ $BUILD_STATUS -eq 0 ]; then
        echo -e "\n"
        echo -e "$green << compile kernel success! >> \n$white"
        echo -e "\n"
        pack_kernel
    else
        echo -e "\n"
        echo -e "$red << compile kernel failed! >> \n$white"
        echo -e "\n"

        END_TIME=$(date +%s)
        DIFF=$((END_TIME - START_TIME))
        DATE_BUILD=$(date +"%A, %B %d, %Y | %H:%M:%S ETC")
        MD5_CHECKSUM=$(md5sum "$WORK_DIR/build.log" | awk '{ print $1 }')

        tg_post_error() {
            $TELEGRAM -f "$1" -t $TELEGRAM_TOKEN -c $CHATIDQ -T "Build Summary
Build failed to compile after \`$((DIFF / 60)) minute(s) and $((DIFF % 60)) second(s)\`
Date build : \`$DATE_BUILD\`
Docker OS : \`$DOCKER_OS\`
MD5 Checksum : \`$MD5_CHECKSUM\`"
        }

        tg_post_error "$WORK_DIR/build.log"
    fi
}

# exe
clean
build_kernel
