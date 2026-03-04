import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Services.System
import qs.Services.Compositor
import qs.Widgets

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    icon: "camera"
    tooltipText: pluginApi?.tr("bar.tooltip") || "Take a screenshot"
    tooltipDirection: BarService.getTooltipDirection()
    baseSize: Style.capsuleHeight
    applyUiScale: false
    customRadius: Style.radiusL
    colorBg: Style.capsuleColor
    colorFg: Color.mOnSurface
    colorBorder: "transparent"
    colorBorderHover: "transparent"
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    onClicked: {
        if (pluginApi) {
            pluginApi.openPanel(root.screen, root)
        }
    }

    onMiddleClicked: {
        if (pluginApi) {
            pluginApi.mainInstance.takeQuickShot()
        }
    }

    onRightClicked: {
        var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
        if (popupMenuWindow) {
            popupMenuWindow.showContextMenu(contextMenu);
            contextMenu.openAtItem(root, screen);
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": I18n.tr("actions.widget-settings"),
                "action": "widget-settings",
                "icon": "settings"
            },
        ]

        onTriggered: action => {
            var popupMenuWindow = PanelService.getPopupMenuWindow(screen);
            if (popupMenuWindow) {
                popupMenuWindow.close();
            }

            if (action === "widget-settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }
}
