#!/bin/bash
#
# Copyright (C) 2023 sirNewbies
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

    cp $KERN_IMG $ANYKERNEL/Image
    cd $ANYKERNEL || exit
    zip -r9 $ZIPNAME ./*

    $TELEGRAM -f $ZIPNAME -t $TELEGRAM_TOKEN -c $CHATIDQ
    echo -e "\n"
    echo -e "$green << kernel uploaded to telegram >>"
    echo -e "\n"
}

function build_kernel() {
    echo -e "\n"
    echo -e "$yrllow << building kernel >> \n$white"
    echo -e "\n"
    
    cd $WORK_DIR
    LTO=thin BUILD_CONFIG=garnet/build.config.gki.custom build/build.sh 2>&1 | tee build.log && cat build.log | nc termbin.com 9999

    if [ -e "$KERN_IMG" ]; then
        echo -e "\n"
        echo -e "$green << compile kernel success! >> \n$white"
        echo -e "\n"
        pack_kernel
    else
        echo -e "\n"
        echo -e "$red << compile kernel failed! >> \n$white"
        echo -e "\n"
    fi
}

# exe
clean
build_kernel
