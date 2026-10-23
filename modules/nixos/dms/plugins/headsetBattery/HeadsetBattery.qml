import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Bar pill: wireless headset battery, as `headsetcontrol -b -o json` reports it.
//
// The kernel exposes no power_supply for the Audeze Maxwell 2, so
// UPower (and DMS's built-in battery widget with it) never sees the headset.
// headsetcontrol asks the dongle directly over hidraw instead; its udev rules
// (services.udev.packages in the host) are what let it do that unprivileged.
//
// The pill hides itself when there is nothing to report: no supported dongle
// plugged in, or the dongle is in but the headset is switched off
// (BATTERY_UNAVAILABLE).
PluginComponent {
    id: root

    // Shape of the first entry in `devices[]`, reduced to what the pill needs.
    property var headset: null
    property bool failed: false
    property string errorText: ""
    property bool lowNotified: false

    readonly property int pollSeconds: pluginData?.pollSeconds ?? 60
    readonly property bool notifyLow: pluginData?.notifyLow !== false
    readonly property int lowThreshold: pluginData?.lowThreshold ?? 15

    readonly property string status: headset?.battery?.status ?? ""
    readonly property int level: headset?.battery?.level ?? -1
    readonly property bool isCharging: status === "BATTERY_CHARGING"
    readonly property bool hasLevel: (status === "BATTERY_AVAILABLE" || isCharging) && level >= 0
    readonly property bool isLow: hasLevel && !isCharging && level < lowThreshold
    // HIDERROR / TIMEOUT: the dongle answered enumeration but not the query —
    // in practice the udev rule is missing and hidraw is still root-only.
    readonly property bool isError: failed || status === "BATTERY_HIDERROR" || status === "BATTERY_TIMEOUT"
    readonly property bool shown: isError || hasLevel || isCharging

    readonly property string iconName: {
        if (isError)
            return "error";
        if (isCharging)
            return "battery_charging_full";
        if (isLow)
            return "battery_alert";
        return "headphones";
    }
    readonly property color tone: isError || isLow ? Theme.error : isCharging ? Theme.primary : Theme.widgetIconColor
    readonly property string levelText: hasLevel ? level + "%" : ""

    readonly property string headline: {
        if (failed)
            return errorText || "Could not run headsetcontrol";
        if (isError)
            return "Headset found, but it did not answer (" + status + ")";
        if (isCharging)
            return hasLevel ? "Charging, " + level + "%" : "Charging";
        if (hasLevel)
            return level + "% battery";
        return "Headset off";
    }

    function applyVisibility() {
        setVisibilityOverride(root.shown);
    }

    function checkLow() {
        if (!root.hasLevel || root.isCharging || root.level >= root.lowThreshold + 5) {
            // Re-arm once it has been charged back up, with a little hysteresis
            // so a level hovering on the threshold does not notify repeatedly.
            if (root.isCharging || root.level >= root.lowThreshold + 5)
                root.lowNotified = false;
            return;
        }
        if (root.isLow && root.notifyLow && !root.lowNotified) {
            root.lowNotified = true;
            Proc.runCommand("headsetBattery.notify", ["notify-send", "-a", "Headset", "-i", "audio-headset", "-u", "critical", "Headset battery low", (root.headset?.device ?? "Headset") + " is at " + root.level + "%"], () => {}, 0);
        }
    }

    function refresh() {
        // headsetcontrol exits non-zero when no device is found or a query
        // fails, but still prints valid JSON — so parse first, judge after.
        Proc.runCommand("headsetBattery.read", ["headsetcontrol", "-b", "-o", "json"], (out, code) => {
            let parsed = null;
            try {
                parsed = JSON.parse(out);
            } catch (e) {
                parsed = null;
            }
            if (parsed && Array.isArray(parsed.devices)) {
                const withBattery = parsed.devices.filter(d => d.battery !== undefined);
                root.headset = withBattery.length > 0 ? withBattery[0] : null;
                root.failed = false;
                root.errorText = "";
            } else {
                root.headset = null;
                root.failed = true;
                root.errorText = code === 127 ? "headsetcontrol is not installed" : "Could not read headsetcontrol output";
            }
            root.applyVisibility();
            root.checkLow();
        }, 0);
    }

    // triggeredOnStart does the initial load, so no Component.onCompleted here —
    // PluginComponent already uses that hook to load pluginData.
    Timer {
        interval: root.pollSeconds * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    pillClickAction: () => root.refresh()

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: root.widgetThickness

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.iconName
                    size: root.iconSize
                    color: root.tone
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.levelText
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: root.isLow ? Theme.error : Theme.widgetTextColor
                    visible: root.levelText !== ""
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.widgetThickness
            implicitHeight: vColumn.implicitHeight

            Column {
                id: vColumn
                anchors.centerIn: parent
                spacing: 2

                DankIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: root.iconName
                    size: root.iconSize
                    color: root.tone
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.hasLevel ? String(root.level) : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.isLow ? Theme.error : Theme.widgetTextColor
                    visible: root.hasLevel
                }
            }
        }
    }
}
