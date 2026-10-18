import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var status: ({})
    property bool available: false
    readonly property bool connected: available && status.Connected === true
    readonly property int overall: {
        if (!connected)
            return -1;
        const values = [status.BatteryLeft, status.BatteryRight].filter(v => validBattery(v));
        return values.length ? Math.min(...values) : -1;
    }
    readonly property string summary: !available ? "Service unavailable" : !connected ? "Disconnected" : "Overall " + percent(overall)

    function validBattery(value) {
        return typeof value === "number" && value >= 0 && value <= 100;
    }
    function percent(value) {
        return validBattery(value) ? value + "%" : "—";
    }
    function battery(value, charging) {
        return connected ? percent(value) + (charging ? " · Charging" : "") : "—";
    }
    function refresh() {
        if (!request.running)
            request.running = true;
    }

    ccWidgetIcon: "headphones"
    ccWidgetPrimaryText: "AirPods"
    ccWidgetSecondaryText: summary
    ccWidgetIsActive: connected
    ccWidgetIsToggle: false
    onCcWidgetExpanded: refresh()
    onCcWidgetToggled: refresh()
    ccDetailHeight: 310
    ccDetailContent: details

    Component {
        id: details
        Column {
            spacing: Theme.spacingM
            StyledText {
                text: root.connected ? (root.status.ModelName || "AirPods") : "AirPods · " + root.summary
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeLarge
            }
            Repeater {
                model: [
                    {label: "Overall", value: root.connected ? root.percent(root.overall) : "—"},
                    {label: "Left bud", value: root.battery(root.status.BatteryLeft, root.status.ChargingLeft)},
                    {label: "Right bud", value: root.battery(root.status.BatteryRight, root.status.ChargingRight)},
                    {label: "Case", value: root.battery(root.status.BatteryCase, root.status.ChargingCase)}
                ]
                delegate: Row {
                    required property var modelData
                    width: parent.width
                    StyledText {
                        width: parent.width * 0.45
                        text: modelData.label
                        color: Theme.surfaceVariantText
                    }
                    StyledText {
                        text: modelData.value
                        color: Theme.surfaceText
                    }
                }
            }
            StyledText {
                width: parent.width
                text: root.connected ? "In ear: " + (root.status.EarLeft ? "Left" : "") + (root.status.EarLeft && root.status.EarRight ? " + " : "") + (root.status.EarRight ? "Right" : "") + (!root.status.EarLeft && !root.status.EarRight ? "Neither" : "") : "Connect your AirPods using Bluetooth."
                wrapMode: Text.Wrap
                color: Theme.surfaceText
            }
            StyledText {
                width: parent.width
                text: "Overall uses the lower reported bud level. Case battery may be unavailable while closed."
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    Process {
        id: request
        command: ["airpods-cli", "--json", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                    root.available = true;
                } catch (error) {
                    root.status = {};
                    root.available = false;
                }
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.status = {};
                root.available = false;
            }
        }
    }
    Timer {
        interval: 5000
        running: root.surfaceLive
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
