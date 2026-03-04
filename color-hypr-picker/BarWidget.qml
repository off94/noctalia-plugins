import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

NIconButton {
    id: root

    property var pluginApi: null

    // Required properties for bar widgets
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""


    applyUiScale: false
    icon: "color-picker"
    tooltipText: pluginApi?.tr("bar.tooltip") || "Color Picker"
    tooltipDirection: BarService.getTooltipDirection()
    baseSize: Style.capsuleHeight

    implicitWidth: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)
    implicitHeight: applyUiScale ? Math.round(baseSize * Style.uiScaleRatio) : Math.round(baseSize)

    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBorder: "transparent"
    colorBorderHover: "transparent"
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth
    radius: Style.radiusM

    onClicked: {
        if (pluginApi) {
            pluginApi.openPanel(root.screen, root)
        }
    }

    onRightClicked: {
        if (pluginApi) {
            pluginApi?.mainInstance?.takePick();
        }
    }
}
