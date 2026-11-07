import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var sample: ({severity: "unknown", used_percent: null})
    property bool refreshing: false
    readonly property string label: {
        if (sample.used_percent === null || sample.used_percent === undefined)
            return "RAM ?";
        const pressure = sample.psi?.some?.avg10;
        return "RAM " + Math.round(sample.used_percent) + "%"
            + (sample.severity !== "normal" ? " · " + sample.severity.toUpperCase() : "")
            + (pressure >= 1 ? " · PSI " + Math.round(pressure) + "%" : "");
    }
    readonly property color statusColor: sample.severity === "critical" ? Theme.error
        : sample.severity === "warning" ? Theme.warning : Theme.widgetTextColor

    horizontalBarPill: Component {
        StyledText {
            text: root.label
            color: root.statusColor
            font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.refreshing)
                return;
            root.refreshing = true;
            Proc.runCommand(null, ["memory-pressure-watch", "status"], (output, exitCode) => {
                root.refreshing = false;
                try {
                    root.sample = exitCode === 0 ? JSON.parse(output) : {severity: "unknown", used_percent: null};
                } catch (error) {
                    root.sample = {severity: "unknown", used_percent: null};
                }
            });
        }
    }
}
