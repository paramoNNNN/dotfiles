import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property var profiles: []
    property string profileError: ""
    property string pendingProfileId: ""

    readonly property var selectedProfile: profiles.find(profile => profile.selected) || null
    readonly property string selectedLabel: {
        if (!selectedProfile)
            return TailscaleService.connected ? TailscaleService.tailnetName : "Disconnected";
        return selectedProfile.nickname || selectedProfile.account || selectedProfile.tailnet;
    }

    Ref {
        service: TailscaleService
    }

    ccWidgetIcon: "device_hub"
    ccWidgetPrimaryText: "Tailscale"
    ccWidgetSecondaryText: profileError.length > 0 ? "Account access unavailable" : selectedLabel
    ccWidgetIsActive: TailscaleService.connected

    onCcWidgetToggled: {
        if (!TailscaleService.available)
            return;
        if (TailscaleService.connected)
            TailscaleService.disconnectTailscale(null);
        else
            TailscaleService.connectTailscale(null);
    }

    function refreshProfiles() {
        if (!profilesProcess.running)
            profilesProcess.running = true;
    }

    function parseProfiles(output) {
        try {
            const parsed = JSON.parse(output);
            profiles = Array.isArray(parsed) ? parsed : [];
            profileError = "";
        } catch (error) {
            profiles = [];
            profileError = "Could not read Tailscale accounts";
        }
    }

    function switchProfile(profileId) {
        if (!profileId || switchProcess.running)
            return;
        pendingProfileId = profileId;
        switchProcess.command = ["tailscale", "switch", profileId];
        switchProcess.running = true;
    }

    Process {
        id: profilesProcess
        command: ["tailscale", "switch", "--list", "--json"]

        stdout: StdioCollector {
            onStreamFinished: root.parseProfiles(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message.length > 0)
                    root.profileError = message;
            }
        }
    }

    Process {
        id: switchProcess

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message.length > 0)
                    ToastService.showError("Tailscale account switch failed", message);
            }
        }

        onExited: exitCode => {
            if (exitCode === 0)
                ToastService.showInfo("Tailscale", "Account switched");
            pendingProfileId = "";
            refreshProfiles();
            TailscaleService.refresh(null);
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refreshProfiles()
    }

    ccDetailContent: Component {
        Rectangle {
            implicitHeight: details.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.nestedSurface
            border.color: Theme.outlineMedium
            border.width: Theme.layerOutlineWidth

            Column {
                id: details
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                StyledText {
                    text: TailscaleService.connected ? "Connected" : "Disconnected"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                StyledText {
                    visible: TailscaleService.tailnetName.length > 0
                    text: TailscaleService.tailnetName
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    elide: Text.ElideRight
                }

                DankDropdown {
                    width: parent.width
                    text: "Account"
                    enabled: root.profiles.length > 0 && !switchProcess.running
                    currentValue: root.selectedLabel
                    options: root.profiles.map(profile => profile.nickname || profile.account || profile.tailnet)
                    onValueChanged: value => {
                        const profile = root.profiles.find(item => (item.nickname || item.account || item.tailnet) === value);
                        if (profile && !profile.selected)
                            root.switchProfile(profile.id);
                    }
                }

                StyledText {
                    visible: root.profileError.length > 0
                    text: root.profileError
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                StyledText {
                    visible: root.profiles.length < 2 && root.profileError.length === 0
                    text: "Add another account with ‘tailscale login’, then select it here."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
