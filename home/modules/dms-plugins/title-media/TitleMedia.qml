import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var popoutService: null
    readonly property var player: MprisController.activePlayer
    readonly property string title: MprisController.stableTitle || ""
    readonly property bool isPlaying: root.player !== null && root.player.playbackState === 1

    pillClickAction: (x, y, width, section, screen) => {
        popoutService?.toggleDankDash("media", x, y, width, section, screen);
    }

    horizontalBarPill: Component {
        Item {
            visible: root.player !== null && root.title.length > 0
            implicitWidth: visible ? Math.min(mediaRow.implicitWidth, 310) : 0
            implicitHeight: root.widgetThickness

            Row {
                id: mediaRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                Row {
                    id: equalizer
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: 18
                    height: 16

                    Repeater {
                        model: [7, 13, 9, 15]

                        Rectangle {
                            required property int modelData
                            required property int index
                            width: 3
                            height: root.isPlaying ? modelData : 3
                            anchors.bottom: parent.bottom
                            radius: 1.5
                            color: Theme.primary

                            SequentialAnimation on height {
                                running: root.isPlaying
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 4 + ((index * 5) % 11)
                                    duration: 180 + index * 35
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 15 - ((index * 3) % 8)
                                    duration: 220 + index * 30
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }

                StyledText {
                    id: titleText
                    width: Math.min(implicitWidth, 280)
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    color: Theme.widgetTextColor
                    font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }
        }
    }
}
