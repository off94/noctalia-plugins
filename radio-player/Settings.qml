import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.Keyboard
import qs.Widgets

ColumnLayout {
    id: root

    spacing: Style.marginM

    property var pluginApi: null

    property var radioList:
        pluginApi?.pluginSettings?.radioList ||
        pluginApi?.manifest?.metadata?.defaultSettings?.radioList ||
        []

    Component.onCompleted: {
        Logger.i("RADIO", "Settings UI loaded");
        loadRadios();
    }

    ListModel {
        id: radioListModel
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        NLabel {
            label: pluginApi?.tr("settings.radioList.title") || "Radio list"
            description: pluginApi?.tr("settings.radioList.description") || "Left-click to drag and re-order, right-click to remove"
        }

        NListView {
            id: listView
            model: radioListModel

            Layout.fillHeight: true
            Layout.fillWidth: true
            horizontalPolicy: ScrollBar.AlwaysOff
            verticalPolicy: ScrollBar.AsNeeded

            delegate: ItemDelegate {
                id: delegateRoot

                bottomPadding: Style.marginS
                highlighted: ListView.view.currentIndex === index
                property int even: index % 2 === 0
                hoverEnabled: true
                leftPadding: Style.marginM
                rightPadding: Style.marginM
                topPadding: Style.marginS
                width: listView.width

                background: Rectangle {
                    anchors.fill: parent
                    color: mouseArea.removing ? Color.mError : mouseArea.dragging ? Color.mSecondary : highlighted ? Color.mHover : even ? Color.mOutline : Color.mSurfaceVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                }

                contentItem: NText {
                    color: mouseArea.removing ? Color.mOnError : mouseArea.dragging ? Color.mOnSecondary : highlighted ? Color.mOnHover : even ? Color.mOnSurface : Color.mOnSurface
                    elide: Text.ElideRight
                    pointSize: Style.fontSizeM
                    text: model.name
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    drag.target: null

                    property int startIndex: index
                    property bool dragging: false
                    property bool removing: false

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onPressed: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            startIndex = index
                            dragging = true
                            listView.interactive = false
                        } else if (mouse.button === Qt.RightButton) {
                            removing = true
                        }
                    }

                    onReleased: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            dragging = false
                            listView.interactive = true
                        } else if (mouse.button === Qt.RightButton) {
                            removing = false
                            radioListModel.remove(index)
                        }
                    }

                    onPositionChanged: {
                        if (!dragging) return;
                        const yInList = mouse.y + delegateRoot.y
                        const itemHeight = delegateRoot.height
                        let toIndex = Math.floor(yInList / itemHeight)

                        toIndex = Math.max(0, Math.min(toIndex, radioListModel.count - 1))

                        if (toIndex !== startIndex) {
                            radioListModel.move(startIndex, toIndex, 1)
                            startIndex = toIndex
                        }
                    }
                }

                onHoveredChanged: {
                    if (hovered) {
                        ListView.view.currentIndex = index;
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.marginS


            NTextInput {
                id: nameField
                placeholderText: pluginApi?.tr("settings.radioList.name") || "Name"
            }

            NTextInput {
                id: urlField
                placeholderText: pluginApi?.tr("settings.radioList.url") || "URL"
            }

            NButton {
                text: pluginApi?.tr("settings.radioList.add") || "Add"
                onClicked: {
                    if (urlField.text.length === 0 || nameField.text.length === 0)
                        return;
                    radioListModel.append({
                        name: nameField.text,
                        url: urlField.text
                    });
                    urlField.text = "";
                    nameField.text = "";
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Style.marginS


            NTextInput {
                id: importField
                placeholderText: pluginApi?.tr("settings.radioList.pasteToImport") || "Paste JSON"
            }

            NButton {
                text: pluginApi?.tr("settings.radioList.import") || "Import"
                onClicked: {
                    if (importField.text.length === 0)
                        return;
                    const object = JSON.parse(importField.text);
                    radioListModel.clear();
                    object.radioList.forEach(item => {
                        radioListModel.append({
                            name: item.name,
                            url: item.url
                        });
                    });
                    importField.text = "";
                }
            }

            NButton {
                icon: "clipboard-text"
                text: pluginApi?.tr("settings.radioList.export") || "Export"
                onClicked: {
                    const object = {"radioList": root.pluginApi.pluginSettings.radioList};
                    const exportData = JSON.stringify(object);
                    ClipboardService.pasteText(exportData);
                }
            }
        }
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("RADIO", "Cannot save settings: pluginApi is null");
            return;
        }

        const newRadios = syncRadios();

        pluginApi.pluginSettings.radioList = newRadios;

        pluginApi.saveSettings();

        Logger.i("RADIO", "Settings saved successfully");
    }

    function loadRadios() {
        radioListModel.clear();

        for (let i = 0; i < root.radioList.length; i++) {
            radioListModel.append({
                name: root.radioList[i].name,
                url: root.radioList[i].url
            })
        }
        logRadios();
    }

    function syncRadios() {
        const newRadios = [];
        for (let i = 0; i < radioListModel.count; i++) {
            const item = radioListModel.get(i);
            newRadios.push({"name": item.name, "url": item.url})
        }
        logRadios();
        return newRadios;
    }

    function logRadios() {
        for (let i = 0; i < root.radioList.length; i++) {
            Logger.d("RADIO", root.radioList[i].name)
        }
    }
}
