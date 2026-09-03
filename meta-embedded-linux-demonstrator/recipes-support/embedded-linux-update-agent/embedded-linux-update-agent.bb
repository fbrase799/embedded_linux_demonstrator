SUMMARY = "A/B software update agent"
DESCRIPTION = "Privileged daemon that validates update bundles and installs them into the inactive rootfs slot."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "python3 libubootenv-bin e2fsprogs-mke2fs util-linux tar gzip"

SRC_URI = "\
    file://eld-update-agent.py \
    file://eld-update-agent.service \
    file://eld-prepare-data.service \
"

S = "${WORKDIR}"

inherit systemd

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/eld-update-agent.py ${D}${sbindir}/eld-update-agent

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/eld-update-agent.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${WORKDIR}/eld-prepare-data.service ${D}${systemd_system_unitdir}/
}

SYSTEMD_SERVICE:${PN} = "eld-update-agent.service eld-prepare-data.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += "${sbindir}/eld-update-agent ${systemd_system_unitdir}/*.service"
