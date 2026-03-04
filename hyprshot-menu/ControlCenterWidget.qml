import QtQuick
import Quickshell
import qs.Widgets

NIconButton {
    property var pluginApi: null
    property ShellScreen screen

    icon: "camera"
    tooltipText: pluginApi?.tr("bar.tooltip") || "Take a screenshot"

    onClicked: {
        if (pluginApi) {
            pluginApi.togglePanel(screen, this)
        }
    }
}
