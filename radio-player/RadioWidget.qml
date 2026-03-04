import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Widgets

Item {
    id: root

    property var radioData
    property bool playing: false
    property int pid: -1

    signal startedPlaying(var data)
    signal stoppedPlaying(var data)

    width: parent.width
    height: 60

    Component.onCompleted: {
        root.playing = pluginApi.mainInstance.currentPlayPid === root.pid
    }

    Rectangle {
        id: rectangle
        anchors.fill: parent
        radius: Style.radiusM
        color: Color.mOnPrimary

        Row {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: Style.marginL
            }
            spacing: Style.radiusL

            NButton {
                text: root.playing ? "⏸" : "▶"
                width: 40
                height: 40
                backgroundColor: root.playing ? Color.mError : Color.mPrimary
                textColor: root.playing ? Color.mOnError : Color.mOnPrimary
                onClicked: root.toggleRadio()
            }

            Text {
                text: radioData.name
                color: Color.mOnSurface
                font.pixelSize: Style.fontSizeXL
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                width: rectangle.width - 40 - Style.marginL * 2
            }
        }
    }

    Connections {
        target: contentColumn
        function onPlayingPidChanged() {
            if (contentColumn.playingPid !== root.pid) {
                stopRadio();
            }
        }
    }

    function playRadio() {
        if (root.playing) return;
        Quickshell.execDetached([
            "mpv",
            "--no-video",
            "--player-operation-mode=pseudo-gui",
            "--force-window=no",
            "--idle=yes",
            "--input-ipc-server=/tmp/noctalia-radio-mpv-socket",
            `--title=Noctalia-Radio-${radioData.name}`,
            radioData.url
        ])
        root.playing = true;
        pluginApi.mainInstance.currentPlayPid = root.pid;
        startedPlaying(root.radioData)
        Logger.i("RADIO", `Playing: ${radioData.name}`)
    }

    function stopRadio() {
        if (!root.playing) return;
        Quickshell.execDetached([
            "pkill",
            "-f",
            `Noctalia-Radio-${radioData.name}`
        ]);
        root.playing = false;
        Logger.i("RADIO", `Stopping: ${radioData.name}`)
    }

    function toggleRadio() {
        if (root.playing) {
            stopRadio();
            pluginApi.mainInstance.currentMarquee = pluginApi?.tr("panel.defMarquee");
            pluginApi.mainInstance.currentPlayPid = -1;
            stoppedPlaying(root.radioData)
        } else {
            playRadio();
        }
    }
}
