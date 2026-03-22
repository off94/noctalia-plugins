import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var radioData
    readonly property bool playing: pluginApi?.mainInstance?.currentPlayPid === root.pid
    property int pid: -1

    signal startedPlaying(var data)
    signal stoppedPlaying(var data)

    width: parent.width
    height: 60

    onPlayingChanged: {
        if (playing) {
            startedPlaying(root.radioData);
        } else {
            stoppedPlaying(root.radioData);
        }
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

    function toggleRadio() {
        pluginApi.mainInstance.toggleRadio(root.pid);
    }
}
