import QtQuick
import QtQuick.Window
import QtQuick.Layouts

Window {
    id: root

    // Stay on the primary output (DSI). A clone target must not swapBuffers.
    screen: {
        const screens = Qt.application.screens
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === "DSI1" || screens[i].name === "DSI-1")
                return screens[i]
        }
        return Qt.application.primaryScreen
    }

    width: 1280
    height: 800
    visible: true
    title: "Embedded Linux Demonstrator"
    visibility: Window.FullScreen

    color: "#071018"

    // Native DSI mode is 720x1280. When the panel is mounted landscape,
    // rotate the UI if the kernel has not already swapped the mode.
    readonly property bool portraitNative: height > width

    Item {
        id: stage
        width: root.portraitNative ? root.height : root.width
        height: root.portraitNative ? root.width : root.height
        rotation: root.portraitNative ? 90 : 0
        anchors.centerIn: parent

        Loader {
            id: pageLoader
            anchors.fill: parent
            sourceComponent: mainPage
        }
    }

    function showUpdate() {
        pageLoader.sourceComponent = updatePage
    }

    function showMain() {
        pageLoader.sourceComponent = mainPage
    }

    Component {
        id: mainPage

        Item {
            Rectangle {
                anchors.fill: parent
                color: "#071018"
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 36
                spacing: 24

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        spacing: 4

                        Text {
                            text: "Embedded Linux Demonstrator"
                            font.pixelSize: 34
                            font.bold: true
                            color: "#E8F1F5"
                        }

                        Text {
                            text: "Raspberry Pi 4  ·  Yocto  ·  Qt 6  ·  U-Boot A/B"
                            font.pixelSize: 16
                            color: "#7FA3B5"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        radius: 6
                        color: "#102433"
                        implicitWidth: slotLabel.implicitWidth + 28
                        implicitHeight: 40

                        Text {
                            id: slotLabel
                            anchors.centerIn: parent
                            text: "Slot " + sysInfo.currentSlot
                            color: "#26C6DA"
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#1C3A4D"
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 2
                    columnSpacing: 24
                    rowSpacing: 24

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#0C1C27"
                        border.color: "#1C3A4D"
                        radius: 8

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 28
                            spacing: 14

                            Text {
                                text: "Device"
                                font.pixelSize: 22
                                font.bold: true
                                color: "#26C6DA"
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#1C3A4D" }

                            InfoRow { label: "Hostname"; value: sysInfo.hostname }
                            InfoRow { label: "Linux Kernel"; value: sysInfo.kernelVersion }
                            InfoRow { label: "Yocto Release"; value: sysInfo.yoctoRelease }
                            InfoRow { label: "Application"; value: sysInfo.applicationVersion }
                            InfoRow { label: "Uptime"; value: sysInfo.uptime }
                            InfoRow { label: "IP Address"; value: sysInfo.ipAddress }

                            Item { Layout.fillHeight: true }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#0C1C27"
                        border.color: "#1C3A4D"
                        radius: 8

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 28
                            spacing: 14

                            Text {
                                text: "Software"
                                font.pixelSize: 22
                                font.bold: true
                                color: "#26C6DA"
                            }

                            Rectangle { Layout.fillWidth: true; height: 1; color: "#1C3A4D" }

                            InfoRow { label: "Current Image"; value: sysInfo.imageVersion }
                            InfoRow { label: "Machine"; value: sysInfo.machine }
                            InfoRow { label: "Active Slot"; value: sysInfo.currentSlot }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.preferredHeight: 56
                                Layout.preferredWidth: 240
                                radius: 6
                                color: "#26C6DA"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Software Update"
                                    color: "#071018"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton
                                    onClicked: root.showUpdate()
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.showUpdate()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: updatePage
        UpdateScreen {
            onBackRequested: root.showMain()
        }
    }

    component InfoRow: RowLayout {
        property string label
        property string value

        Layout.fillWidth: true
        spacing: 16

        Text {
            text: label
            color: "#7FA3B5"
            font.pixelSize: 18
            Layout.preferredWidth: 180
        }

        Text {
            text: value
            color: "#E8F1F5"
            font.pixelSize: 18
            font.bold: true
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
        }
    }
}
