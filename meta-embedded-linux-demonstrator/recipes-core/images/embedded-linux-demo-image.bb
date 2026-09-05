SUMMARY = "Embedded Linux Demonstrator image for Raspberry Pi 4"
DESCRIPTION = "Boots into the Qt demonstrator UI with U-Boot A/B rootfs updates."
LICENSE = "MIT"

IMAGE_FEATURES += "ssh-server-openssh debug-tweaks"

inherit core-image populate_sdk_qt6
IMAGE_CLASSES += "eld-update-bundle"

IMAGE_INSTALL = "\
    packagegroup-core-boot \
    packagegroup-core-ssh-openssh \
    \
    qtbase \
    qtdeclarative \
    fontconfig \
    ttf-dejavu-sans \
    libinput \
    kernel-modules \
    udev-rules-rpi \
    \
    embedded-linux-ui \
    embedded-linux-update-agent \
    embedded-linux-demo-config \
    u-boot-default-env \
    \
    libubootenv-bin \
    e2fsprogs \
    e2fsprogs-mke2fs \
    e2fsprogs-tune2fs \
    util-linux \
    tar \
    gzip \
    xz \
    \
    gdbserver \
    rsync \
    openssh-sftp-server \
    \
    os-release \
    procps \
    iproute2 \
    iputils-ping \
    ca-certificates \
    \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

IMAGE_FSTYPES = "wic wic.bmap tar.gz eldupdate"
IMAGE_FSTYPES:remove = "rpi-sdimg ext3 ext4"

WKS_FILE = "embedded-linux-demo.wks"
WKS_FILE_DEPENDS:append = " virtual/bootloader virtual/kernel dosfstools-native mtools-native eld-dsi-panel-overlay"

# Symbols for remote debugging of the Qt application (stripped binary still ships).
IMAGE_INSTALL:append = " embedded-linux-ui-dbg"

rootfs_eld_finalize() {
    echo "${DISTRO_VERSION}" > ${IMAGE_ROOTFS}/etc/image-version
    echo "${MACHINE}" > ${IMAGE_ROOTFS}/etc/image-machine
    mkdir -p ${IMAGE_ROOTFS}/data ${IMAGE_ROOTFS}/boot

    if ! grep -q "LABEL=boot" ${IMAGE_ROOTFS}/etc/fstab 2>/dev/null; then
        echo "LABEL=boot  /boot  vfat  defaults,sync  0  0" >> ${IMAGE_ROOTFS}/etc/fstab
    fi
    if ! grep -q "LABEL=data" ${IMAGE_ROOTFS}/etc/fstab 2>/dev/null; then
        echo "LABEL=data  /data  ext4  defaults,nofail  0  2" >> ${IMAGE_ROOTFS}/etc/fstab
    fi
}
ROOTFS_POSTPROCESS_COMMAND += "rootfs_eld_finalize;"
