#!/bin/bash

set -x 
#RUN ME on ARM64 Hardware!
# CPU_ARCH=$(uname -m)
# if [[ "$CPU_ARCH" != "aarch64" ]]; then
#     echo "Build script must run on ARM64 hardware.  Please rerun"
#     exit 1
# fi

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


sudo apt -y install make tar wget curl rpm qemu-utils genisoimage bison gawk pigz

if ! [ -f "/usr/bin/go" ];then
    #Go isn't installed.  Go installed it
    sudo add-apt-repository ppa:longsleep/golang-backports
    sudo apt-get update
    sudo apt-get -y install golang-1.15-go
    sudo ln -vsf /usr/lib/go-1.15/bin/go /usr/bin/go    
fi

if ! [ -d "CBL-Mariner" ]; then
    #CBL-Mariner isn't cloned.  Grab it
    git clone https://github.com/microsoft/CBL-Mariner.git    
fi

if ! [ -d "CBL-MarinerDemo" ]; then
    #CBL-MarinerDemo isn't cloned.  Grab it
    git clone https://github.com/microsoft/CBL-MarinerDemo.git
fi

#Build the toolkit
pushd CBL-Mariner/toolkit
git checkout 2.0-stable
#Clean the output just in case
sudo make clean

#Go go gadget toolkit
sudo make package-toolkit REBUILD_TOOLS=y
popd


pushd CBL-MarinerDemo
#Clean out any old toolkit archives
rm toolkit-*.tar.gz
#Copy the toolkit from Mariner and extract it here
cp ../CBL-Mariner/out/toolkit-*.tar.gz ./
tar -xzvf toolkit-*.tar.gz
popd

# Build kernel spec
cp -R CBL-Mariner/SPECS/kernel CBL-MarinerDemo/SPECS/
KERNEL_PACKAGE_NAME=kernel
mv CBL-MarinerDemo/SPECS/kernel CBL-MarinerDemo/SPECS/$KERNEL_PACKAGE_NAME
pushd CBL-MarinerDemo/SPECS/$KERNEL_PACKAGE_NAME
# pull tarball locally from GitHub repo
KVER=5.15.41.1
wget https://github.com/microsoft/CBL-Mariner-Linux-Kernel/archive/rolling-lts/mariner-2/$KVER.tar.gz -O kernel-$KVER.tar.gz
popd

pushd CBL-MarinerDemo/toolkit
#Go make an iso out of the default demo_iso
sudo make clean
sudo make build-packages
#sudo make iso CONFIG_FILE=../imageconfigs/demo_iso.json
popd

