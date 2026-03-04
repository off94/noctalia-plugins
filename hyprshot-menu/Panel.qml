import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 680 * Style.uiScaleRatio
    property real contentPreferredHeight: 540 * Style.uiScaleRatio

    anchors.fill: parent

    property real speed: Settings.data.general.animationSpeed
    readonly property real minSpeed: 0.05
    readonly property real maxSpeed: 2.0
    readonly property int maxDelay: 5000
    readonly property int graceTime: 100
    property int baseDelay: 0


    Component.onCompleted: {
        // Calculate current baseDelay needed to avoid closing panel at screenshot
        root.speed = Math.max(root.minSpeed, Math.min(root.maxSpeed, root.speed))
        if (Settings.data.general.animationDisabled) {
            root.speed = root.maxSpeed;
        }
        root.baseDelay = root.maxDelay * (root.minSpeed / root.speed) + root.graceTime
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginL
            }
            spacing: Style.marginL

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusL

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: Style.marginL
                    }
                    spacing: Style.marginM

                    RowLayout {
                        NIcon {
                            icon: "camera"
                            color: Color.mPrimary
                        }

                        NText {
                            text: pluginApi?.tr("panel.title") || "HyprShot Menu"
                            pointSize: Style.fontSizeL
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                        }
                    }

                    RowLayout {
                        spacing: Style.marginM
                        Layout.fillWidth: true
                        Layout.preferredHeight: parent.height / 2

                        NIconButton {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            applyUiScale: false
                            baseSize: Math.min(width, height)
                                border.width : Style.marginM

                                icon: "device-desktop"
                                tooltipText: pluginApi?.tr("panel.output") || "Output"
                                onClicked: {
                                    pluginApi.mainInstance.takeShotAfter(root.baseDelay + pluginApi.mainInstance.delay, "output", pluginApi.mainInstance.output, pluginApi.mainInstance.clipboardOnly, pluginApi.mainInstance.freeze);
                                    pluginApi.closePanel(root.screen);
                                }
                            }


                            NIconButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                applyUiScale: false
                                baseSize: Math.min(width, height)
                                border.width : Style.marginM

                                icon: "app-window"
                                tooltipText: pluginApi?.tr("panel.window") || "Window"
                                onClicked: {
                                    pluginApi.mainInstance.takeShotAfter(root.baseDelay + pluginApi.mainInstance.delay, "window", pluginApi.mainInstance.output, pluginApi.mainInstance.clipboardOnly, pluginApi.mainInstance.freeze);
                                    pluginApi.closePanel(root.screen);
                                }
                            }

                            NIconButton {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                applyUiScale: false
                                baseSize: Math.min(width, height)
                                border.width : Style.marginM

                                icon: "maximize"
                                tooltipText: pluginApi?.tr("panel.region") || "Region"
                                onClicked: {
                                    pluginApi.mainInstance.takeShotAfter(root.baseDelay + pluginApi.mainInstance.delay, "region", pluginApi.mainInstance.output, pluginApi.mainInstance.clipboardOnly, pluginApi.mainInstance.freeze);
                                    pluginApi.closePanel(root.screen);
                                }
                            }
                    }

                    RowLayout {
                        spacing: Style.marginM
                        Layout.fillWidth: true
                        Layout.preferredHeight: parent.height / 2

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Color.mOutline
                            radius: Style.radiusL

                            NComboBox {
                                anchors.centerIn: parent

                                label: pluginApi?.tr("panel.output") || "Output"
                                placeholder: pluginApi.mainInstance.output.name
                                defaultValue: pluginApi.mainInstance.output.name
                                currentKey: pluginApi.mainInstance.output.key
                                model: pluginApi.mainInstance.outputs
                                onSelected: (key) => {
                                    let item = pluginApi.mainInstance.outputList.find(o => o.key === key)
                                    if (!item) {
                                        item = {key: "active", name: pluginApi?.tr("panel.active") || "Active"}
                                    }
                                    pluginApi.mainInstance.output = item
                                    pluginApi.pluginSettings.output = item
                                    pluginApi.saveSettings()
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: Style.marginM

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Color.mOutline
                                radius: Style.radiusL

                                NSpinBox {
                                    id: delaySelector
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: Style.marginL

                                    label: pluginApi?.tr("panel.delay") || "Delay"
                                    value: pluginApi.mainInstance.delay
                                    from: 0
                                    to: 10000
                                    stepSize: 500
                                    suffix: " ms"
                                    onValueChanged: () => {
                                        pluginApi.mainInstance.delay = delaySelector.value
                                        pluginApi.pluginSettings.delay_ms = delaySelector.value
                                        pluginApi.saveSettings()
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Color.mOutline
                                radius: Style.radiusL

                                NToggle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: Style.marginL

                                    label: pluginApi?.tr("panel.clipboardOnly") || "Clipboard only"
                                    checked: pluginApi.mainInstance.clipboardOnly
                                    onToggled: (checked) => {
                                        pluginApi.mainInstance.clipboardOnly = checked
                                        pluginApi.pluginSettings.no_save = checked
                                        pluginApi.saveSettings()
                                    }
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Color.mOutline
                                radius: Style.radiusL

                                NToggle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.right: parent.right
                                    anchors.rightMargin: Style.marginL

                                    label: pluginApi?.tr("panel.freeze") || "Freeze"
                                    checked: pluginApi.mainInstance.freeze
                                    onToggled: (checked) => {
                                        pluginApi.mainInstance.freeze = checked
                                        pluginApi.pluginSettings.freeze = checked
                                        pluginApi.saveSettings()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
