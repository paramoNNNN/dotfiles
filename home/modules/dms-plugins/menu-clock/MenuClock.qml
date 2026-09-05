import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null

    SystemClock {
        id: systemClock
        precision: SystemClock.Minutes
    }

    pillClickAction: (x, y, width, section, screen) => {
        if (!popoutService)
            return;
        // Unlike built-in widgets, plugins must activate lazy popout loaders.
        popoutService.notificationCenterLoader.active = true;
        Qt.callLater(() => {
            popoutService.toggleNotificationCenter(x, y, width, section, screen);
        });
    }

    horizontalBarPill: Component {
        StyledText {
            text: Qt.formatDateTime(systemClock.date, "ddd MMM d HH:mm")
            color: Theme.widgetTextColor
            font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
            verticalAlignment: Text.AlignVCenter
        }
    }
}
