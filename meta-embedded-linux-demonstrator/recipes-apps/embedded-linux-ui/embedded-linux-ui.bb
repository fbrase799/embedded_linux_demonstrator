SUMMARY = "Qt demonstrator application"
DESCRIPTION = "Device UI showing system information and software update controls."
HOMEPAGE = "https://github.com/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=28f50f94c04412814cfe0a835871a320"

DEPENDS = "qtbase qtdeclarative qtdeclarative-native"

EXTERNALSRC ?= "${TOPDIR}/../application/embedded-linux-ui"
EXTERNALSRC_BUILD ?= "${WORKDIR}/build"

inherit externalsrc qt6-cmake systemd

PV = "${DISTRO_VERSION}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
EXTRA_OECMAKE += "-DAPP_VERSION=${DISTRO_VERSION}"

SRC_URI += "file://embedded-linux-ui.service"

SYSTEMD_SERVICE:${PN} = "embedded-linux-ui.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    if [ -f "${UNPACKDIR}/embedded-linux-ui.service" ]; then
        install -m 0644 ${UNPACKDIR}/embedded-linux-ui.service ${D}${systemd_system_unitdir}/
    else
        install -m 0644 ${WORKDIR}/embedded-linux-ui.service ${D}${systemd_system_unitdir}/
    fi
}

FILES:${PN} += "${systemd_system_unitdir}/embedded-linux-ui.service"

RDEPENDS:${PN} += "\
    qtbase \
    qtbase-plugins \
    qtdeclarative \
    fontconfig \
    ttf-dejavu-sans \
"
