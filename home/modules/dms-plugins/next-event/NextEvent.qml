import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null
    property string eventTitle: ""
    property int remainingSeconds: 0
    property bool loading: true

    readonly property string eventLabel: {
        if (loading)
            return "";
        if (!eventTitle)
            return "No upcoming events for today";
        return eventTitle + " · " + root.remainingLabel();
    }

    pillClickAction: (x, y, width, section, screen) => {
        popoutService?.toggleDankDash(0, x, y, width, section, screen);
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: eventRow.implicitWidth
            implicitHeight: root.widgetThickness

            Row {
                id: eventRow
                anchors.centerIn: parent

                StyledText {
                    width: Math.min(implicitWidth, 360)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.eventLabel
                    color: Theme.widgetTextColor
                    font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshEvent()
    }

    function refreshEvent() {
        Proc.runCommand(null, ["dms-next-event"], (output, exitCode) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.clearEvent();
                return;
            }

            try {
                const event = JSON.parse(output);
                root.eventTitle = event.title || "";
                root.remainingSeconds = event.remainingSeconds || 0;
                return;
            } catch (error) {}
            root.clearEvent();
        });
    }

    function remainingLabel() {
        const minutes = Math.max(1, Math.ceil(remainingSeconds / 60));
        if (minutes < 60)
            return "in " + minutes + (minutes === 1 ? " min" : " mins");

        const hours = Math.floor(minutes / 60);
        const extraMinutes = minutes % 60;
        if (extraMinutes === 0)
            return "in " + hours + (hours === 1 ? " hr" : " hrs");
        return "in " + hours + (hours === 1 ? " hr " : " hrs ") + extraMinutes + " min";
    }

    function clearEvent() {
        eventTitle = "";
        remainingSeconds = 0;
    }
}
