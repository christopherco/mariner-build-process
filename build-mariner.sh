#!/bin/bash
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update

sudo apt install -y make tar wget curl rpm qemu-utils golang-1.15-go genisoimage bison gawk pigz

sudo apt install -y qemu qemu-system qemu-efi qemu-system-aarch64

sudo ln -vsf /usr/lib/go-1.15/bin/go /usr/bin/go

git clone https://github.com/microsoft/CBL-Mariner.git
pushd CBL-Mariner/toolkit
git checkout 1.0-stable
sudo make package-toolkit REBUILD_TOOLS=y
popd

git clone https://github.com/microsoft/CBL-MarinerDemo.git
pushd CBL-MarinerDemo
cp ../CBL-Mariner/out/toolkit-*.tar.gz ./
tar -xzvf toolkit-*.tar.gz

pushd toolkit


sudo make iso CONFIG_FILE=../imageconfigs/demo_iso.json UNATTENDED_INSTALLER=y