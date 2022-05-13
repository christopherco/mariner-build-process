#!/bin/bash

MARINER_ISO=""
MARINER_RUN_DIR="CBL-Mariner-Run"
MARINER_BUILD_TAR="mariner-amd64.tar.gz"
PKGS='qemu qemu-system qemu-efi qemu-system-x86 qemu-system-x86 qemu-utils'
FLASH0="flash0-x86.img"
FLASH1="flash1-x86.img" 
DATADRIVE="mariner-data-drive-x86.gcow2" 
CORECOUNT=$(nproc)
MAX_CORE_COUNT=32
MAX_MEMORY_GB=64
MEMORY_GB=$(grep MemTotal /proc/meminfo | awk '{print $2}') #Memory is in KB first
MEMORY_GB=$((((MEMORY_GB))/1024)) #Convert KB to MB
MEMORY_GB=$((((MEMORY_GB))/1024)) #Convert MB to GB

#RUN ME on X86_64 Hardware!
CPU_ARCH=$(uname -m)
if [[ "$CPU_ARCH" != "x86_64" ]]; then
    echo "Boot script must run on x64 hardware.  Please rerun"
    exit 1
fi


#Check if the demo_iso director is available
if [ ! -d "$MARINER_RUN_DIR/demo_iso" ]; then
    #Check if the tar ball from build-mariner-arm64.sh is available
    if [ ! -f "$MARINER_RUN_DIR/$MARINER_BUILD_TAR" ]; then
        echo "Boot script unable to find '$MARINER_RUN_DIR/$MARINER_BUILD_TAR'.  Run 'build-mariner-amd64.sh' on x86 hardware and copy to $MARINER_RUN_DIR"
        exit 1    
    fi
    pushd $MARINER_RUN_DIR
    tar -xvf $MARINER_BUILD_TAR    
    popd
fi


ISO_FILES=($MARINER_RUN_DIR/demo_iso/*.iso)
MARINER_ISO=${ISO_FILES[0]}

if [[ -z "$MARINER_ISO" ]]; then
    echo "Unable to find Mariner ISO for install.  Run 'build-mariner-amd64.sh' on x86 hardware and copy to $MARINER_RUN_DIR"
    exit 1
fi

#Run as sudo if we're not already
if ! [[ "$EUID" = 0 ]]; then    
    sudo -k # make sure to ask for password on next sudo
    if sudo true; then
        echo "(2) correct password"
    else
        echo "(3) wrong password"
        exit 1
    fi
fi

#Our machine has more memory than our configured max.  Set it to the max
if [[ $MEMORY_GB -gt $MAX_MEMORY_GB ]]; then
    MEMORY_GB=$MAX_MEMORY_GB
fi

#Our machine has more cores than our configured max.  Set it to the max
if [[ $CORECOUNT -gt $MAX_CORE_COUNT ]]; then
    CORECOUNT=$MAX_CORE_COUNT
fi


#Install any packages that are missing
if ! dpkg -s $PKGS >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get install --no-install-recommends -y $PKGS
fi

if [ ! -f "$MARINER_RUN_DIR/$DATADRIVE" ]; then
  qemu-img create "$MARINER_RUN_DIR/$DATADRIVE" 128G -f qcow2
fi

if [ ! -f "$MARINER_RUN_DIR/$FLASH0" ]; then
  dd if=/dev/zero of="$MARINER_RUN_DIR/$FLASH0" bs=1M count=64
  dd if=/usr/share/qemu-efi/QEMU_EFI.fd of="$MARINER_RUN_DIR/$FLASH0" conv=notrunc
fi

if [ ! -f "$MARINER_RUN_DIR/$FLASH1" ]; then 
  dd if=/dev/zero of="$MARINER_RUN_DIR/$FLASH1" bs=1M count=64
fi

echo ""
echo ""
echo "-------------------------"
echo "Everything is setup - starting Mariner via QEMU.  This may take a couple of minutes"
echo "-------------------------"
echo ""
echo ""

qemu-system-x86_64 -nographic \
    -m ${MEMORY_GB}G \
    -cpu max \
    -netdev user,id=vnet,hostfwd=:127.0.0.1:0-:22 -device virtio-net-pci,netdev=vnet \
    -drive file=${MARINER_RUN_DIR}/${DATADRIVE},if=none,id=drive0,cache=writeback -device virtio-blk,drive=drive0,bootindex=0 \
    -drive file=${MARINER_ISO},if=none,id=drive1,cache=writeback -device virtio-blk,drive=drive1,bootindex=1