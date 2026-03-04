import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.Keyboard
import qs.Services.UI
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    IpcHandler {
        target: "plugin:color-hypr-picker"
        function toggle() {
            if (pluginApi) {
                pluginApi.withCurrentScreen(screen => {
                    pluginApi.openPanel(screen);
                });
            }
        }
        function pick() {
            takePick();
        }
    }

    readonly property int colorListSize: 30

    property var colorList:
        pluginApi?.pluginSettings?.colorList ||
        pluginApi?.manifest?.metadata?.defaultSettings?.colorList ||
        []
    property ListModel colorListModel: ListModel {}

    onColorListChanged: {
        colorListModel.clear()

        if (!colorList)
            return

            for (let i = 0; i < colorList.length; i++) {
                colorListModel.append({ colorCode: colorList[i] })
            }
    }

    function hasValue(o) {return o !== undefined && o !== null}
    function setValue(settingsValue, defaultSettingsValue, defaultValue) {
        if (hasValue(settingsValue)) return settingsValue;
        if (hasValue(defaultSettingsValue)) return defaultSettingsValue;
        return defaultValue;
    }

    Process {
        id: picker
        command: ["sh", "-c",'hyprpicker --format=hex | grep -v "^\[ERR\]" | tail -n 1']
        running: false

        stdout: SplitParser {
            onRead: line => {
                const data = line.trim();
                const hex = data.match(/^#[0-9A-Fa-f]{6}$/)?.[0];
                if (hex === undefined || hex === null) return;
                Logger.i("ColorPicker", `Color clicked: ${hex}`);
                const colorCode = getColorCodeFormatted(hex, false);
                ClipboardService.pasteText(colorCode);

                addColor(hex);
                pluginApi.pluginSettings.currentColor = hex;
                pluginApi.pluginSettings.colorList = listModelToArray();
                pluginApi.saveSettings();
            }
        }
    }

    Timer {
        id: tTimer
        running: false
        repeat: false
        triggeredOnStart: false
        onTriggered: takePick()
    }

    function takePick() {
        picker.running = true;return;
    }

    function takePickAfter(time) {
        tTimer.interval = time
        tTimer.restart()
    }

    function addColor(newColor) {
        colorListModel.insert(0, { colorCode: newColor })
        if (colorListModel.count > colorListSize)
            colorListModel.remove(colorListSize - 1)
    }

    function removeColor(index) {
        if (index >= 0 && index < colorListModel.count)
            colorListModel.remove(index)
    }

    function deleteAll() {
        Logger.i("ColorPicker", `All colors deleted`);
        colorListModel.clear()
        pluginApi.pluginSettings.colorList = []
        pluginApi.saveSettings()
    }

    function listModelToArray() {
        const arr = []
        for (let i = 0; i < colorListModel.count; i++) {
            arr.push(colorListModel.get(i).colorCode)
        }
        return arr
    }

    function getColorCodeFormatted(colorCode, newlines) {
        if (colorCode === undefined || colorCode === null) return "";
        switch (pluginApi.pluginSettings.currentFormat) {
            case "hex":
                return colorCode;
            case "rgb":
                return hexToRgbString(colorCode, newlines);
            case "hsl":
                return hexToHslString(colorCode, newlines);
            case "hsv":
                return hexToHsvString(colorCode, newlines);
            case "cmyk":
                return hexToCmykString(colorCode, newlines);
        }
        return "?";
    }

    function hexToRgbObject(hex) {
        if (!hex || hex.length !== 7 || hex[0] !== "#")
            return null

            var r = parseInt(hex.substr(1, 2), 16)
            var g = parseInt(hex.substr(3, 2), 16)
            var b = parseInt(hex.substr(5, 2), 16)

            return { r: r, g: g, b: b }
    }

    function hexToRgbString(hex, newlines) {
        var c = hexToRgbObject(hex);
        if (!c) return null;
        return newlines ? `rgb(${c.r}, \n${c.g}, \n${c.b})` : `rgb(${c.r}, ${c.g}, ${c.b})`;
    }

    function hexToHslString(hex, newlines) {
        var c = hexToRgbObject(hex)
        if (!c) return null

            var r = c.r / 255
            var g = c.g / 255
            var b = c.b / 255

            var max = Math.max(r, g, b)
            var min = Math.min(r, g, b)
            var h, s, l = (max + min) / 2

            if (max === min) {
                h = s = 0
            } else {
                var d = max - min
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min)

                switch (max) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break
                    case g: h = (b - r) / d + 2; break
                    case b: h = (r - g) / d + 4; break
                }

                h /= 6
            }

            return newlines ? `hsl(${Math.round(h * 360)}, \n${Math.round(s * 100)}%, \n${Math.round(l * 100)}%)`
            : `hsl(${Math.round(h * 360)}, ${Math.round(s * 100)}%, ${Math.round(l * 100)}%)`;
    }

    function hexToHsvString(hex, newlines) {
        var c = hexToRgbObject(hex)
        if (!c) return null

            var r = c.r / 255
            var g = c.g / 255
            var b = c.b / 255

            var max = Math.max(r, g, b)
            var min = Math.min(r, g, b)
            var d = max - min

            var h = 0
            var s = max === 0 ? 0 : d / max
            var v = max

            if (d !== 0) {
                switch (max) {
                    case r: h = (g - b) / d + (g < b ? 6 : 0); break
                    case g: h = (b - r) / d + 2; break
                    case b: h = (r - g) / d + 4; break
                }
                h /= 6
            }

            return newlines ? `hsv(${Math.round(h * 360)}, \n${Math.round(s * 100)}%, \n${Math.round(v * 100)}%)`
            : `hsv(${Math.round(h * 360)}, ${Math.round(s * 100)}%, ${Math.round(v * 100)}%)`;
    }

    function hexToCmykString(hex, newlines) {
        var c = hexToRgbObject(hex)
        if (!c) return null

            var r = c.r / 255
            var g = c.g / 255
            var b = c.b / 255

            var k = 1 - Math.max(r, g, b)

            var cC = (1 - r - k) / (1 - k) || 0
            var m = (1 - g - k) / (1 - k) || 0
            var y = (1 - b - k) / (1 - k) || 0

            return newlines ? `cmyk(\n${Math.round(cC * 100)}%, ${Math.round(m * 100)}%, \n${Math.round(y * 100)}%, ${Math.round(k * 100)}%)`
            : `cmyk(${Math.round(cC * 100)}%, ${Math.round(m * 100)}%, ${Math.round(y * 100)}%, ${Math.round(k * 100)}%)`;
    }
}
