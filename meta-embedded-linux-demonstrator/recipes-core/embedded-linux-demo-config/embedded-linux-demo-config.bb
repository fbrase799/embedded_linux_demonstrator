SUMMARY = "Device configuration for the Embedded Linux Demonstrator"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = "\
    file://20-wired.network \
    file://fw_env.config \
    file://data.mount \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${WORKDIR}/20-wired.network ${D}${sysconfdir}/systemd/network/20-wired.network

    install -d ${D}${sysconfdir}
    install -m 0644 ${WORKDIR}/fw_env.config ${D}${sysconfdir}/fw_env.config

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/data.mount ${D}${systemd_system_unitdir}/data.mount

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_system_unitdir}/systemd-networkd.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-networkd.service
    ln -sf ${systemd_system_unitdir}/systemd-resolved.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-resolved.service
}

SYSTEMD_SERVICE:${PN} = "data.mount"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "\
    ${sysconfdir}/systemd/network \
    ${sysconfdir}/fw_env.config \
    ${sysconfdir}/systemd/system/multi-user.target.wants \
    ${systemd_system_unitdir}/data.mount \
"
