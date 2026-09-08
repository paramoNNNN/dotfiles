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
    readonly property string artist: MprisController.stableArtist || ""
    readonly property string displayText: root.artist.length > 0 ? root.artist + " - " + root.title : root.title
    readonly property string artUrl: TrackArtService.resolvedArtUrl || root.player?.trackArtUrl || ""
    readonly property bool isPlaying: root.player !== null && root.player.playbackState === 1

    pillClickAction: (x, y, width, section, screen) => {
        popoutService?.toggleDankDash("media", x, y, width, section, screen);
    }

    horizontalBarPill: Component {
        Item {
            visible: root.player !== null && root.title.length > 0
            implicitWidth: visible ? mediaRow.implicitWidth : 0
            implicitHeight: root.widgetThickness

            Row {
                id: mediaRow
                anchors.centerIn: parent
                spacing: Theme.spacingS

                MediaArtwork {
                    id: artwork
                    width: Math.min(24, root.widgetThickness - 6)
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    artUrl: root.artUrl
                    cornerRadius: 5
                }

                Loader {
                    active: root.isPlaying
                    sourceComponent: Component {
                        Ref {
                            service: CavaService
                        }
                    }
                }

                Row {
                    id: equalizer
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    width: 18
                    height: 16

                    Repeater {
                        model: 4

                        Rectangle {
                            required property int index
                            readonly property real level: {
                                const value = CavaService.values[index] || 0;
                                return Math.sqrt(Math.max(0, Math.min(100, value)) / 100);
                            }

                            width: 3
                            height: root.isPlaying ? 3 + level * 11 : 3
                            anchors.bottom: parent.bottom
                            radius: width / 2
                            color: Theme.primary

                            Behavior on height {
                                NumberAnimation {
                                    duration: 40
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }

                StyledText {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.displayText
                    color: Theme.widgetTextColor
                    font.pixelSize: Theme.barTextSize(root.barThickness, 1.07)
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
