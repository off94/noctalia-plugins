import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.Services.System
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    property string currentMarquee: ""
    property int currentPlayPid: -1

    property var radioList:
        pluginApi?.pluginSettings?.radioList ||
        pluginApi?.manifest?.metadata?.defaultSettings?.radioList ||
        []

    IpcHandler {
        target: "plugin:radio-player"
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
            }
        }
        function play(index: int) {
            // Index is 1-based from the IPC call to use keyboard order, convert to 0-based
            root.playRadio(index-1);
        }
        function stop() {
            root.stopRadio();
        }
    }

    Timer {
        interval: 5000
        running: root.currentPlayPid !== -1
        repeat: true
        onTriggered: {
            checkCurrentSong.running = true
        }
    }

    Process {
        id: checkCurrentSong
        command: ["sh", "-c", "echo '{\"command\":[\"get_property\",\"metadata\"]}' | socat - /tmp/noctalia-radio-mpv-socket"]
        running: false

        stdout: SplitParser {
            onRead: line => {
                const data = extractUsefulData(line);
                if (data) {
                    try {
                        root.currentMarquee = data["icy-name"] || data["icy-title"] || data["title"];
                    } catch(e) {
                        root.currentMarquee = pluginApi?.tr("main.errorMarquee");
                    }
                }
            }
        }
    }


    function playRadio(index) {
        const radio = radioList[index];
        if (!radio) {
            return;
        }
        if (currentPlayPid !== -1) {
            stopRadio();
        }
        Quickshell.execDetached([
            "mpv",
            "--no-video",
            "--player-operation-mode=pseudo-gui",
            "--force-window=no",
            "--idle=yes",
            "--input-ipc-server=/tmp/noctalia-radio-mpv-socket",
            `--title=Noctalia-Radio-${radio.name}`,
            radio.url
        ]);
        currentPlayPid = index;
        Logger.i("RADIO", `Playing: ${radio.name}`);
    }

    function stopRadio() {
        if (currentPlayPid === -1) {
            return;
        }
        const radio = radioList[currentPlayPid];
        if (radio) {
            Quickshell.execDetached(["pkill", "-f", `Noctalia-Radio-${radio.name}`]);
            Logger.i("RADIO", `Stopping: ${radio.name}`);
        }
        currentPlayPid = -1;
        currentMarquee = pluginApi?.tr("panel.defMarquee") || "No music";
    }

    function toggleRadio(index) {
        if (currentPlayPid === index) {
            stopRadio();
        } else {
            playRadio(index);
        }
    }

    function extractUsefulData(jsonText) {
        if (!jsonText) return null;

        const result = {};

        const titleMatch = /"title"\s*:\s*"([^"]*)"/.exec(jsonText);
        if (titleMatch && titleMatch[1]) {
            result["title"] = titleMatch[1];
        }

        const icyRegex = /"icy-[^"]*"\s*:\s*"([^"]*)"/g;
        let match;
        while ((match = icyRegex.exec(jsonText)) !== null) {
            const key = match[0].split(":")[0].replace(/"/g, "");
            result[key] = match[1];
        }

        return result;
    }

}
