SUMMARY = "Device configuration for the Embedded Linux Demonstrator"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = "\
    file://20-wired.network \
    file://fw_env.config \
    file://data.mount \
    file://eld-ensure-dsi-overlay \
    file://eld-ensure-dsi-overlay.service \
    file://eld-dsi.conf \
"

S = "${WORKDIR}"

do_install() {
    src="${UNPACKDIR}"
    [ -f "${src}/20-wired.network" ] || src="${WORKDIR}"

    install -d ${D}${sysconfdir}/systemd/network
    install -m 0644 ${src}/20-wired.network ${D}${sysconfdir}/systemd/network/20-wired.network

    install -d ${D}${sysconfdir}
    install -m 0644 ${src}/fw_env.config ${D}${sysconfdir}/fw_env.config

    install -d ${D}${sbindir}
    install -m 0755 ${src}/eld-ensure-dsi-overlay ${D}${sbindir}/eld-ensure-dsi-overlay

    install -d ${D}${sysconfdir}/modules-load.d
    install -m 0644 ${src}/eld-dsi.conf ${D}${sysconfdir}/modules-load.d/eld-dsi.conf

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${src}/data.mount ${D}${systemd_system_unitdir}/data.mount
    install -m 0644 ${src}/eld-ensure-dsi-overlay.service ${D}${systemd_system_unitdir}/eld-ensure-dsi-overlay.service

    install -d ${D}${sysconfdir}/systemd/system/multi-user.target.wants
    ln -sf ${systemd_system_unitdir}/systemd-networkd.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-networkd.service
    ln -sf ${systemd_system_unitdir}/systemd-resolved.service \
        ${D}${sysconfdir}/systemd/system/multi-user.target.wants/systemd-resolved.service
}

SYSTEMD_SERVICE:${PN} = "data.mount eld-ensure-dsi-overlay.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "\
    ${sysconfdir}/systemd/network \
    ${sysconfdir}/fw_env.config \
    ${sbindir}/eld-ensure-dsi-overlay \
    ${sysconfdir}/modules-load.d/eld-dsi.conf \
    ${sysconfdir}/systemd/system/multi-user.target.wants \
    ${systemd_system_unitdir}/data.mount \
    ${systemd_system_unitdir}/eld-ensure-dsi-overlay.service \
"
