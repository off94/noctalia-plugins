import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Keyboard
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
        // Calculate current baseDelay needed to avoid closing panel at color pick
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
                            icon: "color-picker"
                            color: Color.mPrimary
                        }

                        NText {
                            text: pluginApi?.tr("panel.title") || "Color Picker"
                            pointSize: Style.fontSizeL
                            font.weight: Font.Bold
                            color: Color.mOnSurface
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NColorPicker {
                            Layout.preferredWidth: 180
                            screen: pluginApi?.panelOpenScreen
                            selectedColor: pluginApi?.pluginSettings?.currentColor
                            onColorSelected: color => {
                                const colorCode = colorToHex(color);
                                Logger.i("ColorPicker", `Color generated: ${colorCode}`);
                                pluginApi?.mainInstance?.addColor(colorCode);
                                pluginApi.pluginSettings.currentColor = colorCode;
                                pluginApi.pluginSettings.colorList = pluginApi?.mainInstance?.listModelToArray();
                                pluginApi.saveSettings();
                            }
                        }

                        NButton {
                            icon: "color-picker"
                            text: pluginApi?.tr("panel.pick") || "Pick from screen"
                            onClicked: {
                                pluginApi.mainInstance.takePickAfter(root.baseDelay);
                                pluginApi.closePanel(root.screen);
                            }
                        }

                        NButton {
                            icon: "layout-grid-remove"
                            color: Color.mError
                            text: pluginApi?.tr("panel.remove") || "Delete all"
                            onClicked: pluginApi?.mainInstance?.deleteAll()
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Color.mOutline
                        radius: Style.radiusM

                        clip: true

                        GridView {
                            id: colorGrid
                            anchors.fill: parent
                            anchors.margins: Style.marginL

                            readonly property int colorSize: 100

                            cellWidth: colorSize + Style.marginM
                            cellHeight: colorSize + Style.marginM

                            model: pluginApi?.mainInstance?.colorListModel

                            delegate: Rectangle {
                                width: colorGrid.colorSize
                                height: colorGrid.colorSize
                                radius: Style.marginXS
                                color: colorCode

                                border.width: 1
                                border.color: Color.mOnPrimary

                                Text {
                                    anchors.centerIn: parent
                                    text: pluginApi?.mainInstance?.getColorCodeFormatted(colorCode, true)
                                    font.pixelSize: Style.fontSizeL
                                    color: root.getTextColorFromBackground(colorCode)
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Rectangle {
                                    id: pressOverlay
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "#66ff0000"
                                    visible: false
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            selectColor(colorCode, index)
                                        } else if (mouse.button === Qt.RightButton) {
                                            deleteColor(colorCode, index)
                                        }
                                    }

                                    onPressed: function(mouse) {
                                        parent.scale = 0.8
                                        if (mouse.button === Qt.RightButton)
                                            pressOverlay.visible = true
                                    }

                                    onReleased: {
                                        parent.scale = 1.0
                                        pressOverlay.visible = false
                                    }
                                }

                                Behavior on scale {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                        }
                    }

                    ButtonGroup {
                        id: formatValues
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NRadioButton {
                            ButtonGroup.group: formatValues
                            text: "HEX"
                            font.weight: Style.fontWeightMedium
                            checked: pluginApi?.pluginSettings?.currentFormat === "hex"
                            onClicked: setFormat("hex")
                            Layout.fillWidth: true
                        }

                        NRadioButton {
                            ButtonGroup.group: formatValues
                            text: "RGB"
                            font.weight: Style.fontWeightMedium
                            checked: pluginApi?.pluginSettings?.currentFormat === "rgb"
                            onClicked: setFormat("rgb")
                            Layout.fillWidth: true
                        }

                        NRadioButton {
                            ButtonGroup.group: formatValues
                            text: "HSL"
                            font.weight: Style.fontWeightMedium
                            checked: pluginApi?.pluginSettings?.currentFormat === "hsl"
                            onClicked: setFormat("hsl")
                            Layout.fillWidth: true
                        }

                        NRadioButton {
                            ButtonGroup.group: formatValues
                            text: "HSV"
                            font.weight: Style.fontWeightMedium
                            checked: pluginApi?.pluginSettings?.currentFormat === "hsv"
                            onClicked: setFormat("hsv")
                            Layout.fillWidth: true
                        }

                        NRadioButton {
                            ButtonGroup.group: formatValues
                            text: "CMYK"
                            font.weight: Style.fontWeightMedium
                            checked: pluginApi?.pluginSettings?.currentFormat === "cmyk"
                            onClicked: setFormat("cmyk")
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    function selectColor(colorCode, index) {
        Logger.i("ColorPicker", `Color ${index} clicked: ${colorCode}`);
        ClipboardService.pasteText(pluginApi?.mainInstance?.getColorCodeFormatted(colorCode, false));
        pluginApi?.mainInstance?.removeColor(index);
        pluginApi?.mainInstance?.addColor(colorCode);
        pluginApi.pluginSettings.currentColor = colorCode;
        pluginApi.pluginSettings.colorList = pluginApi?.mainInstance?.listModelToArray();
        pluginApi.saveSettings();
    }

    function deleteColor(colorCode, index) {
        Logger.i("ColorPicker", `Color ${index} deleted: ${colorCode}`);
        ClipboardService.pasteText(pluginApi?.mainInstance?.getColorCodeFormatted(colorCode, false));
        pluginApi?.mainInstance?.removeColor(index);
        pluginApi.pluginSettings.currentColor = colorCode;
        pluginApi.pluginSettings.colorList = pluginApi?.mainInstance?.listModelToArray();
        pluginApi.saveSettings();
    }

    function setFormat(format) {
        Logger.i("ColorPicker", `Format changed: ${format}`);
        pluginApi.pluginSettings.currentFormat = format;
        pluginApi.saveSettings();
    }

    function channelToLinear(c) {
        c = c / 255.0
        return (c <= 0.03928) ? (c / 12.92) : Math.pow((c + 0.055) / 1.055, 2.4)
    }

    function getLuminance(colorString) {
        var c = Qt.color(colorString)

        var r = channelToLinear(c.r * 255)
        var g = channelToLinear(c.g * 255)
        var b = channelToLinear(c.b * 255)

        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    function getTextColorFromBackground(colorString) {
        return getLuminance(colorString) > 0.5 ? "black" : "white";
    }

    function colorToHex(colorValue) {
        var c = Qt.color(colorValue)

        function toHex(v) {
            var h = Math.round(v).toString(16)
            return h.length === 1 ? "0" + h : h
        }

        var r = toHex(c.r * 255)
        var g = toHex(c.g * 255)
        var b = toHex(c.b * 255)

        return "#" + r + g + b
    }

}

