SUMMARY = "Default U-Boot environment for A/B slot selection"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "u-boot-tools-native"

SRC_URI = "file://u-boot-initial-env"

S = "${WORKDIR}"
B = "${WORKDIR}/build"

inherit deploy

do_compile() {
    mkdir -p ${B}
    # Scarthgap's mkenvimage (U-Boot 2024.01) has no -B; little-endian is the default.
    mkenvimage -s 0x4000 -o ${B}/uboot.env ${WORKDIR}/u-boot-initial-env
}

do_install() {
    install -d ${D}/boot
    install -m 0644 ${B}/uboot.env ${D}/boot/uboot.env
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/uboot.env ${DEPLOYDIR}/uboot.env
}
addtask deploy after do_compile before do_build

FILES:${PN} += "/boot/uboot.env"
