import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    property string currentMarquee: ""
    property int currentPlayPid: -1

    IpcHandler {
        target: "plugin:radio"
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
            }
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
