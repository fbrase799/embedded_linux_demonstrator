import QtQuick
import QtQuick.Layouts

Item {
    id: root
    signal backRequested()

    Rectangle {
        anchors.fill: parent
        color: "#071018"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 36
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: 120
                radius: 6
                color: "#102433"
                border.color: "#1C3A4D"

                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    color: "#E8F1F5"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.backRequested()
                }
            }

            Text {
                text: "Software Update"
                font.pixelSize: 32
                font.bold: true
                color: "#E8F1F5"
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredHeight: 48
                Layout.preferredWidth: 160
                radius: 6
                color: "#102433"
                border.color: "#1C3A4D"

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    color: "#E8F1F5"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: updater.refresh()
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
            columns: 2
            columnSpacing: 32

            Text { text: "Current Version"; color: "#7FA3B5"; font.pixelSize: 16 }
            Text { text: (updater.currentVersion || sysInfo.imageVersion); color: "#E8F1F5"; font.pixelSize: 18; font.bold: true }

            Text { text: "Active / Inactive Slot"; color: "#7FA3B5"; font.pixelSize: 16 }
            Text { text: (updater.currentSlot + "  →  " + updater.inactiveSlot); color: "#E8F1F5"; font.pixelSize: 18; font.bold: true }
        }

        Text {
            visible: updater.desktopMode
            text: "Desktop mode: the update agent is not available. File selection is simulated."
            color: "#C9A227"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
        }

        Text {
            text: "Update Image"
            color: "#26C6DA"
            font.pixelSize: 20
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0C1C27"
            border.color: "#1C3A4D"
            radius: 8

            ListView {
                id: imageList
                anchors.fill: parent
                anchors.margins: 8
                clip: true

                model: updater.images

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 64

                    color: updater.selectedPath === modelData.path ? "#143044" : "transparent"
                    border.color: updater.selectedPath === modelData.path ? "#26C6DA" : "transparent"
                    radius: 4

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            text: modelData.path
                            color: "#E8F1F5"
                            font.pixelSize: 16
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                        }

                        Text {
                            text: modelData.version || ""
                            color: "#26C6DA"
                            font.pixelSize: 16
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: updater.selectImage(modelData.path)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: imageList.count === 0
                    text: "No update images in /data/updates\nCopy a .eldupdate bundle there, then press Refresh."
                    color: "#7FA3B5"
                    font.pixelSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            color: "#0C1C27"
            border.color: "#1C3A4D"
            radius: 8
            implicitHeight: summaryCol.implicitHeight + 32

            ColumnLayout {
                id: summaryCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 8

                Text {
                    text: updater.selectedPath ? updater.selectedPath : "No image selected"
                    color: "#E8F1F5"
                    font.pixelSize: 16
                    wrapMode: Text.WrapAnywhere
                    Layout.fillWidth: true
                }

                Text {
                    text: updater.selectedSummary
                    color: updater.selectedValid ? "#8FDB8F" : "#7FA3B5"
                    font.pixelSize: 16
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Status: " + updater.message
                color: updater.state === "error" ? "#E57373" : "#E8F1F5"
                font.pixelSize: 16
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Text {
                visible: updater.errorString.length > 0
                text: updater.errorString
                color: "#E57373"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 10
                color: "#1C3A4D"
                visible: updater.busy || updater.progress > 0

                Rectangle {
                    height: parent.height
                    width: parent.width * (Math.max(0, Math.min(updater.progress, 100)) / 100)
                    radius: 10
                    color: "#26C6DA"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Rectangle {
                Layout.preferredHeight: 56
                Layout.preferredWidth: 220
                radius: 6
                color: "#26C6DA"

                opacity: (updater.selectedValid && !updater.busy) ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "Install Update"
                    color: "#071018"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: updater.selectedValid && !updater.busy
                    onClicked: updater.installSelected()
                }
            }

            Rectangle {
                Layout.preferredHeight: 56
                Layout.preferredWidth: 220
                radius: 6
                color: "#102433"
                border.color: "#1C3A4D"

                opacity: (!updater.busy && updater.state === "done") ? 1 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "Reboot Device"
                    color: "#E8F1F5"
                    font.pixelSize: 18
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !updater.busy && updater.state === "done"
                    onClicked: updater.rebootDevice()
                }
            }

            Item { Layout.fillWidth: true }
        }
    }
}
