SUMMARY = "DT overlay so firmware-detected official 7-inch DSI binds on Scarthgap"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://eld-dsi-panel-overlay.dts"

inherit deploy

DEPENDS += "dtc-native"

S = "${WORKDIR}"

do_compile() {
    src="${UNPACKDIR}/eld-dsi-panel-overlay.dts"
    [ -f "$src" ] || src="${WORKDIR}/eld-dsi-panel-overlay.dts"
    dtc -@ -I dts -O dtb -o ${B}/eld-dsi-panel.dtbo "$src"
}

do_deploy() {
    install -d ${DEPLOYDIR}
    install -m 0644 ${B}/eld-dsi-panel.dtbo ${DEPLOYDIR}/eld-dsi-panel.dtbo
}
addtask deploy after do_compile before do_build
