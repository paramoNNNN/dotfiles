import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginComponent {
    id: root

    property string keyboardName: ""
    property string language: "EN"

    pillClickAction: () => {
        if (root.keyboardName.length > 0)
            Quickshell.execDetached(["hyprctl", "switchxkblayout", root.keyboardName, "next"]);
    }

    horizontalBarPill: Component {
        StyledText {
            text: root.language
            color: Theme.widgetTextColor
            font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refreshLayout();
        }
    }

    Component.onCompleted: refreshLayout()

    function refreshLayout() {
        Proc.runCommand(null, ["hyprctl", "-j", "devices"], (output, exitCode) => {
            if (exitCode !== 0)
                return;
            try {
                const keyboard = JSON.parse(output).keyboards.find(kb => kb.main === true);
                if (!keyboard)
                    return;
                root.keyboardName = keyboard.name;
                const layouts = (keyboard.layout || "us").split(",");
                const active = layouts[keyboard.active_layout_index] || "us";
                root.language = active === "ir" ? "FA" : "EN";
            } catch (e) {}
        });
    }
}
