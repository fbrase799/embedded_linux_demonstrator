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

SRC_URI += "\
    file://embedded-linux-ui.service \
    file://embedded-linux-ui-start \
    file://eglfs-dsi.json \
"

SYSTEMD_SERVICE:${PN} = "embedded-linux-ui.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install:append() {
    src="${UNPACKDIR}"
    [ -f "${src}/embedded-linux-ui.service" ] || src="${WORKDIR}"

    install -d ${D}${bindir}
    install -d ${D}${sysconfdir}/embedded-linux-ui
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${src}/embedded-linux-ui.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${src}/embedded-linux-ui-start ${D}${bindir}/
    install -m 0644 ${src}/eglfs-dsi.json ${D}${sysconfdir}/embedded-linux-ui/
}

FILES:${PN} += "\
    ${systemd_system_unitdir}/embedded-linux-ui.service \
    ${bindir}/embedded-linux-ui-start \
    ${sysconfdir}/embedded-linux-ui \
"

RDEPENDS:${PN} += "\
    qtbase \
    qtbase-plugins \
    qtdeclarative \
    fontconfig \
    ttf-dejavu-sans \
    libinput \
"
