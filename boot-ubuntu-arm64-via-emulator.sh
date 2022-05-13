UBUNTU_IMG="ubuntu-21.04-server-cloudimg-arm64.img"
UBUNTU_RUN_DIR="ubuntu-run"
DATA_DRIVE="ubuntu_data_drive.img"
PKGS='qemu qemu-system qemu-efi qemu-system-aarch64 qemu-utils cloud-image-utils qemu-system-arm curl'
FLASH0="flash0-arm64.img"
FLASH1="flash1-arm64.img" 

CORECOUNT=$(nproc)
MAX_CORE_COUNT=8
MAX_MEMORY_GB=32
MEMORY_GB=$(grep MemTotal /proc/meminfo | awk '{print $2}') #Memory is in KB first
MEMORY_GB=$((((MEMORY_GB))/1024)) #Convert KB to MB
MEMORY_GB=$((((MEMORY_GB))/1024)) #Convert MB to GB


# Get the image.
if [ ! -f "${UBUNTU_RUN_DIR}/${UBUNTU_IMG}" ]; then
  curl --output "${UBUNTU_RUN_DIR}/${UBUNTU_IMG}" "https://cloud-images.ubuntu.com/releases/hirsute/release/${UBUNTU_IMG}"
  qemu-img resize "${UBUNTU_RUN_DIR}/${UBUNTU_IMG}" +128G
fi

#Our machine has more memory than our configured max.  Set it to the max
if [[ $MEMORY_GB -gt $MAX_MEMORY_GB ]]; then
    MEMORY_GB=$MAX_MEMORY_GB
fi

#Our machine has more cores than our configured max.  Set it to the max
if [[ $CORECOUNT -gt $MAX_CORE_COUNT ]]; then
    CORECOUNT=$MAX_CORE_COUNT
fi

#Cloud Init Stuff
if [ ! -f "${UBUNTU_RUN_DIR}/${DATA_DRIVE}" ]; then
  cat >"${UBUNTU_RUN_DIR}/${DATA_DRIVE}" <<EOF
#cloud-config
password: asdfqwer
chpasswd: { expire: False }
ssh_pwauth: True
EOF

  cloud-localds "${UBUNTU_RUN_DIR}/${DATA_DRIVE}" "${UBUNTU_RUN_DIR}/${DATA_DRIVE}"

fi

if [ ! -f "$UBUNTU_RUN_DIR/$FLASH0" ]; then
  dd if=/dev/zero of="$UBUNTU_RUN_DIR/$FLASH0" bs=1M count=64
  dd if=/usr/share/qemu-efi/QEMU_EFI.fd of="$UBUNTU_RUN_DIR/$FLASH0" conv=notrunc
fi
if [ ! -f "$UBUNTU_RUN_DIR/$FLASH1" ]; then
  dd if=/dev/zero of="$UBUNTU_RUN_DIR/$FLASH1" bs=1M count=64
fi



qemu-system-aarch64 \
  -M virt \
  -cpu max \
  -device rtl8139,netdev=net0 \
  -m ${MEMORY_GB}G \
  -netdev user,id=net0 \
  -nographic \
  -smp ${CORECOUNT} \
  -drive "if=none,file=${UBUNTU_RUN_DIR}/${UBUNTU_IMG},id=hd0" \
  -device virtio-blk-device,drive=hd0 \
  -drive "file=${UBUNTU_RUN_DIR}/${DATA_DRIVE},format=raw" \
  -pflash ${UBUNTU_RUN_DIR}/${FLASH0} \
  -pflash ${UBUNTU_RUN_DIR}/${FLASH1}
