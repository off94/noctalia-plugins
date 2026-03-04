import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    IpcHandler {
        target: "plugin:hyprshot-menu"
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
            }
        }
        function shot() {
            takeQuickShot();
        }
    }

    property string quickMode
    property string currentMode
    property var output
    property string folder
    property string filename
    property bool freeze
    property int notifTime
    property int delay
    property bool clipboardOnly
    property var outputList
    property ListModel outputs: ListModel {}

    function hasValue(o) {return o !== undefined && o !== null}
    function setValue(settingsValue, defaultSettingsValue, defaultValue) {
        if (hasValue(settingsValue)) return settingsValue;
        if (hasValue(defaultSettingsValue)) return defaultSettingsValue;
        return defaultValue;
    }

    onPluginApiChanged: {
        if (pluginApi) {

            const cfg = pluginApi.pluginSettings ?? {}
            const def = pluginApi.manifest?.metadata?.defaultSettings ?? {}

            quickMode = setValue(cfg.mode, def.mode, "region")
            output = setValue(cfg.output, def.output, {key: "active", name: pluginApi?.tr("panel.active") || "Active"})
            folder = setValue(cfg.folder, def.folder, "~")
            filename = setValue(cfg.filename, def.filename, "ScreenShot")
            freeze = setValue(cfg.freeze, def.freeze, false)
            notifTime = setValue(cfg.notification_ms, def.notification_ms, 5000)
            delay = setValue(cfg.delay_ms, def.delay_ms, 0)
            clipboardOnly = setValue(cfg.no_save, def.no_save, false)
            outputList = setValue(cfg.outputs, def.outputs, [])

            // Get current available outputs
            outputs.clear()
            outputs.append({key: "active", name: pluginApi?.tr("panel.active") || "Active"})
            for (let o of outputList) { // o cfg.outputs
                outputs.append({
                    key: o.key,
                    name: o.name
                })
            }

            monitorsQuery.running = true
        }
    }

    Timer {
        id: tTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: takeShot()
    }

    function takeShot() {
        Logger.d("MAIN HYPRSHOT MENU", "takeShot")
        const command = ["hyprshot"];
        command.push("--mode");
        command.push(root.currentMode);
        if (root.currentMode === "window"){
            command.push("--mode");
            command.push("active");
        } else if (root.currentMode === "output") {
            command.push("--mode");
            command.push(root.output.key);
        }
        if (root.freeze) {
            command.push("--freeze");
        }
        if (root.clipboardOnly) {
            command.push("--clipboard-only");
        } else {
            const d = new Date()
            const pad = (n) => n.toString().padStart(2, '0')

            const year  = d.getFullYear()
            const month = pad(d.getMonth() + 1)
            const day   = pad(d.getDate())
            const hours = pad(d.getHours())
            const min   = pad(d.getMinutes())
            const sec   = pad(d.getSeconds())

            const time = `${year}-${month}-${day}_${hours}-${min}-${sec}`

            command.push("--output-folder");
            command.push(root.folder);
            command.push("--filename");
            command.push(`${root.filename}__${time}.png`);
        }
        if (root.notifTime > 0) {
            command.push("--notif-timeout");
            command.push(root.notifTime);
        } else {
            command.push("--silent");
        }
        Logger.i("MAIN HYPRSHOT MENU", command)
        Quickshell.execDetached(command);
    }

    function takeShotAfter(time, mode, output, clipboardOnly, freeze) {
        Logger.d("MAIN HYPRSHOT MENU", "takeShotAfter")
        tTimer.interval = time
        root.currentMode = mode
        root.output = output
        root.clipboardOnly = clipboardOnly
        root.freeze = freeze
        tTimer.restart()
    }

    function takeQuickShot() {
        Logger.i("MAIN HYPRSHOT MENU", "takeQuickShot", quickMode)
        Quickshell.execDetached(["hyprshot", "--freeze", "--clipboard-only", "--silent", "--mode", quickMode])
    }


    Process {
        id: monitorsQuery
        command: ["sh", "-c", "hyprctl monitors | awk '/Monitor/{print $2}'"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const m = line.trim()
                if (m && !Array.from({length: root.outputs.count}, (_, i) => root.outputs.get(i)).some(e => e.key === m)) {
                    root.outputs.append({key:m, name:m})
                }
            }
        }
    }
}
