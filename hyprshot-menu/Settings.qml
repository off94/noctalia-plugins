import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    spacing: Style.marginM

    property var pluginApi: null

    property int outputToDelete: 1

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("SETTINGS HYPRSHOT MENU", "Cannot save settings - pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.mode = pluginApi.mainInstance.quickMode;
        pluginApi.pluginSettings.folder = pluginApi.mainInstance.folder;
        pluginApi.pluginSettings.filename = pluginApi.mainInstance.filename;
        pluginApi.pluginSettings.outputs = JSON.parse(listModelToString(pluginApi.mainInstance.outputs));
        pluginApi.pluginSettings.notification_ms = pluginApi.mainInstance.notifTime;

        pluginApi.saveSettings();
    }

    function listModelToString(list) {
        const arr = []
        for (let i = 0; i < list.count; i++) {
            if (list.get(i).key === "active") continue;
            arr.push(list.get(i))
        }
        return JSON.stringify(arr)
    }


    NComboBox {
        label: pluginApi?.tr("settings.modeFast.value") || "Mode (Fast action)"
        description: pluginApi?.tr("settings.modeFast.description") || "Mode to use when middle clicking the button"
        Layout.fillWidth: true
        model: [{
            "key": "output", "name": pluginApi?.tr("settings.output") || "Output"
        },{
            "key": "window", "name": pluginApi?.tr("settings.window") || "Window"
        },{
            "key": "region", "name": pluginApi?.tr("settings.region") || "Region"
        }]
        currentKey: pluginApi.mainInstance.quickMode
        onSelected: key => {
            pluginApi.mainInstance.quickMode = key;
        }
    }

    NDivider {}

    NTextInputButton {
        label: pluginApi?.tr("settings.folder.value") || "Path to output"
        description: pluginApi?.tr("settings.folder.description") || "Path where to store screenshots"
        Layout.fillWidth: true
        placeholderText: Quickshell.env("HOME")
        buttonIcon: "folder-open"
        buttonTooltip: pluginApi.tr("settings.folder.value")
        onInputEditingFinished: pluginApi.mainInstance.folder = text
        text: pluginApi.mainInstance.folder
        onButtonClicked: folderPicker.openFilePicker()
    }

    NDivider {}

    NTextInput {
        label: pluginApi?.tr("settings.filename.value") || "Filename"
        description: pluginApi?.tr("settings.filename.description") || "Filename for new screenshots (plus datetime)"
        Layout.fillWidth: true
        placeholderText: "ScreenShot"
        text: pluginApi.mainInstance.filename
        onTextChanged: pluginApi.mainInstance.filename = text
    }

    NDivider {}

    NSpinBox {
        label: pluginApi?.tr("settings.notification_ms.value") || "Notification duration"
        description: pluginApi?.tr("settings.notification_ms.description") || "Time in ms for the notification after screenshot"
        Layout.fillWidth: true
        value: pluginApi.mainInstance.notifTime
        from: 0
        to: 10000
        stepSize: 500
        suffix: " ms"
        onValueChanged: pluginApi.mainInstance.notifTime = value
    }

    NDivider {}

    Item {
        id: outputsBox
        Layout.fillWidth: true
        height: 400

        ColumnLayout {
            anchors.fill: parent
            spacing: Style.marginS

            NLabel {
                label: pluginApi?.tr("settings.outputs.value") || "Output list"
                description: pluginApi?.tr("settings.outputs.description") || "e.g. key: DP-1, name: MyOutput"
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 32
                spacing: Style.marginS


                NTextInput {
                    id: nameField
                    placeholderText: pluginApi?.tr("settings.outputs.name") || "Name"
                }

                NTextInput {
                    id: keyField
                    placeholderText: pluginApi?.tr("settings.outputs.key") || "Key ID"
                }

                NButton {
                    text: pluginApi?.tr("settings.outputs.add") || "Add"
                    onClicked: {
                        if (keyField.text.length === 0 || nameField.text.length === 0)
                            return
                            pluginApi.mainInstance.outputs.append({
                                key: keyField.text,
                                name: nameField.text
                            })

                            keyField.text = ""
                            nameField.text = ""
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                spacing: Style.marginS

                NSpinBox {
                    id: outputDeleteSelector
                    Layout.fillWidth: true
                    value: 1
                    from: 1
                    to: pluginApi.mainInstance.outputs.count - 1
                    stepSize: 1
                    onValueChanged: root.outputToDelete = value
                }
                NButton {
                    text: pluginApi?.tr("settings.outputs.remove") || "Remove"
                    onClicked: {
                        if (pluginApi.mainInstance.outputs.count > 0) {
                            pluginApi.mainInstance.outputs.remove(root.outputToDelete)
                            outputDeleteSelector.value = 1
                            root.outputToDelete = 1
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 150
                spacing: Style.marginS

                NListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150

                    model: pluginApi.mainInstance.outputs
                    clip: true

                    delegate: Rectangle {
                        width: listView.width
                        height: key !== "active" ? 40 : 0
                        visible: key !== "active"
                        color: index % 2 === 0 ? Color.mOutline : Color.mSurfaceVariant

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Style.marginM
                            padding: Style.marginS

                            NText {
                                text: name
                                color: Color.mOnSurfaceVariant
                            }

                            NText {
                                text: `(${key})`
                                color: Color.mOnSurface
                            }
                        }
                    }
                }
            }
        }
    }

    NFilePicker {
        id: folderPicker
        selectionMode: "folders"
        title: pluginApi.tr("settings.folder.value")
        initialPath: pluginApi.mainInstance.folder || Quickshell.env("HOME")
        onAccepted: paths => {
            if (paths.length > 0) {
                pluginApi.mainInstance.folder = paths[0]
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }
}

