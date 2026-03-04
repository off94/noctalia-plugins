import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    property real contentPreferredWidth: 400 * Style.uiScaleRatio
    property real contentPreferredHeight: 540 * Style.uiScaleRatio

    anchors.fill: parent

    property var radioList:
        pluginApi?.pluginSettings?.radioList ||
        pluginApi?.manifest?.metadata?.defaultSettings?.radioList ||
        []


    // Panel
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

            // Actual Content
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Color.mSurfaceVariant
                radius: Style.radiusL

                Item {
                    anchors {
                        fill: parent
                        margins: Style.marginL
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Style.marginL
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true


                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            NIcon {
                                icon: "radio"
                                color: Color.mPrimary
                            }

                            NText {
                                text: pluginApi?.tr("panel.title") || "Radio player"
                                pointSize: Style.fontSizeL
                                font.weight: Font.Bold
                                color: Color.mOnSurface
                            }
                        }

                        // Currently playing
                        Rectangle {
                            id: currentlyPlaying
                            Layout.fillWidth: true
                            Layout.preferredHeight: parent.height * 0.1

                            radius: Style.radiusM
                            color: Color.mOutline
                            clip: true

                            onWidthChanged: Qt.callLater(scrollingText.tryStart)

                            NText {
                                id: scrollingText
                                text: pluginApi?.mainInstance?.currentMarquee || pluginApi?.tr("panel.defMarquee") || "No music"
                                pointSize: Style.fontSizeL
                                font.weight: Font.Bold
                                color: Color.mOnSurface
                                y: (parent.height - height) / 2

                                onTextChanged: {
                                    marqueeAnim.stop()
                                    Qt.callLater(tryStart)
                                }
                                onWidthChanged: Qt.callLater(tryStart)

                                function tryStart() {
                                    if (width <= 0 || currentlyPlaying.width <= 0) return;
                                    if (width > currentlyPlaying.width) {
                                        x = currentlyPlaying.width
                                        marqueeAnim.from = currentlyPlaying.width
                                        marqueeAnim.to = -width
                                        marqueeAnim.restart()
                                    } else {
                                        x = Style.marginL
                                        marqueeAnim.stop()
                                    }
                                }
                            }

                            NumberAnimation {
                                id: marqueeAnim
                                target: scrollingText
                                property: "x"
                                from: parent.width
                                to: -scrollingText.width
                                duration: (parent.width + scrollingText.width) / 100 * 1000
                                loops: Animation.Infinite
                                running: scrollingText.width > currentlyPlaying.width && currentlyPlaying.width > 10
                                easing.type: Easing.Linear
                            }
                        }

                        // Radio stations
                        Rectangle {

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Color.mOutline
                            radius: Style.radiusL

                            Flickable {
                                anchors.fill: parent
                                clip: true

                                contentWidth: width
                                contentHeight: contentColumn.height + Style.marginL * 2

                                Column {
                                    id: contentColumn
                                    x: Style.marginL
                                    y: Style.marginL
                                    width: parent.width - Style.marginL * 2
                                    spacing: Style.marginM

                                    property int playingPid: pluginApi.mainInstance?.currentPlayPid

                                    Repeater {
                                        model: root.radioList
                                        delegate: RadioWidget {
                                            width: parent.width
                                            radioData: modelData
                                            pid: index
                                            onStartedPlaying: function(data) {
                                                scrollingText.tryStart()
                                            }
                                            onStoppedPlaying: function(data) {
                                                scrollingText.tryStart()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
