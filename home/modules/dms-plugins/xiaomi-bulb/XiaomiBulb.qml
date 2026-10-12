import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var bulb: ({})
    property bool connected: false
    property string errorText: ""
    readonly property bool busy: request.running

    ccWidgetIcon: "lightbulb"
    ccWidgetPrimaryText: "Xiaomi Bulb"
    ccWidgetSecondaryText: busy ? "Connecting…" : errorText ? "Unavailable" : connected ? (bulb.on ? bulb.brightness + "% · " + (bulb.colorMode === 2 ? bulb.temperature + " K" : "Color") : "Off") : "Connecting…"
    ccWidgetIsActive: connected && !!bulb.on
    ccDetailHeight: 440

    onCcWidgetToggled: send("toggle")
    onCcWidgetExpanded: send("status")

    function send(action, value) {
        if (busy)
            return;
        let command = ["dms-xiaomi-bulb", action];
        if (value !== undefined)
            command.push(String(value));
        request.command = command;
        request.running = true;
    }

    Process {
        id: request
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const response = JSON.parse(text);
                    if (response.ok) {
                        root.bulb = response;
                        root.connected = true;
                        root.errorText = "";
                    } else {
                        root.connected = false;
                        root.errorText = response.error || "Could not connect to the bulb";
                    }
                } catch (error) {
                    root.connected = false;
                    root.errorText = "Could not read the bulb's response";
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0 && !root.errorText) {
                root.connected = false;
                root.errorText = "Bulb control is unavailable";
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.effectiveVisible
        triggeredOnStart: true
        onTriggered: root.send("status")
    }

    ccDetailContent: Component {
        Rectangle {
            implicitHeight: details.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.nestedSurface

            Column {
                id: details
                width: parent.width - Theme.spacingM * 2
                x: Theme.spacingM
                y: Theme.spacingM
                spacing: Theme.spacingM

                Row {
                    spacing: Theme.spacingS
                    DankButton {
                        text: root.bulb.on ? "Turn off" : "Turn on"
                        iconName: "power_settings_new"
                        enabled: root.connected && !root.busy
                        onClicked: root.send(root.bulb.on ? "off" : "on")
                    }
                    DankButton {
                        text: "Refresh"
                        iconName: "refresh"
                        enabled: !root.busy
                        onClicked: root.send("status")
                    }
                }

                StyledText {
                    visible: root.errorText.length > 0
                    text: root.errorText
                    color: Theme.error
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                }

                StyledText {
                    text: "Brightness"
                    color: Theme.surfaceText
                }
                DankSlider {
                    id: brightnessSlider
                    width: parent.width
                    minimum: 1
                    maximum: 100
                    unit: "%"
                    startIcon: "brightness_low"
                    endIcon: "brightness_high"
                    enabled: root.connected && !!root.bulb.on && !root.busy
                    onSliderDragFinished: finalValue => root.send("brightness", finalValue)
                    Binding {
                        target: brightnessSlider
                        property: "value"
                        value: root.bulb.brightness || 45
                        when: !brightnessSlider.isDragging
                    }
                }

                StyledText {
                    text: "White temperature"
                    color: Theme.surfaceText
                }
                DankSlider {
                    id: temperatureSlider
                    width: parent.width
                    minimum: root.bulb.minTemperature || 1700
                    maximum: root.bulb.maxTemperature || 6500
                    step: 100
                    unit: " K"
                    startIcon: "wb_sunny"
                    endIcon: "ac_unit"
                    enabled: root.connected && !!root.bulb.on && !root.busy
                    onSliderDragFinished: finalValue => root.send("temperature", finalValue)
                    Binding {
                        target: temperatureSlider
                        property: "value"
                        value: root.bulb.temperature || 4900
                        when: !temperatureSlider.isDragging
                    }
                }

                StyledText {
                    text: "Color"
                    color: Theme.surfaceText
                }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    Repeater {
                        model: ["#FF4040", "#FF8800", "#FFD740", "#40DD70", "#40AAFF", "#AA55FF", "#FF60B0"]
                        delegate: Rectangle {
                            required property string modelData
                            width: 30
                            height: 30
                            radius: 15
                            color: modelData
                            opacity: root.connected && root.bulb.on && !root.busy ? 1 : 0.4
                            border.width: root.bulb.color === modelData ? 3 : 1
                            border.color: Theme.surfaceText
                            MouseArea {
                                anchors.fill: parent
                                enabled: root.connected && !!root.bulb.on && !root.busy
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.send("color", parent.modelData)
                            }
                        }
                    }
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    DankTextField {
                        id: colorInput
                        width: Math.max(100, parent.width - applyColor.width - parent.spacing)
                        placeholderText: "#FF8800"
                        maximumLength: 7
                        enabled: root.connected && !!root.bulb.on && !root.busy
                    }
                    DankButton {
                        id: applyColor
                        text: "Apply"
                        enabled: root.connected && !!root.bulb.on && !root.busy && /^#?[0-9a-fA-F]{6}$/.test(colorInput.text)
                        onClicked: root.send("color", colorInput.text)
                    }
                }
            }
        }
    }
}
