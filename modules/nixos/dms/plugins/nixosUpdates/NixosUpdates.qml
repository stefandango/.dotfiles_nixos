import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

// Bar pill: how far the pinned nixpkgs is behind its branch.
//
// All the actual work lives in ~/Scripts/nixupdates — this only renders what
// `--json` reports. The script owns the cache and the 4h refresh window, so
// polling here is cheap and never touches the network on its own.
PluginComponent {
    id: root

    // Absolute: ~/Scripts is not on the shell's PATH.
    readonly property string scriptPath: (Quickshell.env("HOME") || "") + "/Scripts/nixupdates"

    readonly property var emptyDiff: ({
            "fresh": false,
            "status": "stale",
            "count": 0,
            "packages": [],
            "groups": [],
            "message": ""
        })

    // Shape mirrors `nixupdates --json`. Not named `state` — Item already has one.
    property var info: ({
            "status": "unknown",
            "days": 0,
            "current_date": "",
            "latest_date": "",
            "current_rev": "",
            "latest_rev": "",
            "checking": false,
            "diffing": false,
            "diff": root.emptyDiff
        })
    property bool failed: false
    property bool checkCooling: false

    readonly property bool hideWhenIdle: pluginData?.hideWhenIdle !== false
    readonly property int pollSeconds: pluginData?.pollSeconds ?? 600

    readonly property var diff: info.diff ?? root.emptyDiff
    readonly property bool isChecking: !failed && (info.checking === true || info.status === "unknown")
    readonly property bool isOutdated: info.status === "outdated"
    readonly property bool isCurrent: info.status === "current"
    readonly property bool diffFailed: diff.fresh === true && diff.status === "error"
    readonly property bool hasPackages: diff.fresh === true && diff.status === "ok" && diff.count > 0
    // Families the script collapsed (a package's vendored dependency tree). They
    // can outnumber the packages, so the section stays up for these alone.
    readonly property var diffGroups: diff.groups ?? []
    readonly property bool hasGroups: diff.fresh === true && diff.status === "ok" && diffGroups.length > 0

    readonly property string iconName: failed ? "error" : isChecking ? "refresh" : isOutdated ? "system_update_alt" : "check_circle"
    readonly property color tone: failed ? Theme.error : isOutdated ? Theme.primary : Theme.surfaceText

    readonly property string headline: {
        if (failed)
            return "Could not read update status";
        if (isChecking)
            return "Checking…";
        if (isCurrent)
            return "Up to date";
        return info.days + (info.days === 1 ? " day" : " days") + " behind nixpkgs";
    }

    function shortRev(rev) {
        return rev ? String(rev).substring(0, 7) : "—";
    }

    // Collapse the pill to zero width when there is nothing to report, which is
    // what the old waybar module did via `#custom-updates.current { min-width: 0 }`.
    function applyVisibility() {
        setVisibilityOverride(!(hideWhenIdle && isCurrent && !failed));
    }

    function refresh() {
        Proc.runCommand("nixosUpdates.json", [root.scriptPath, "--json"], (out, code) => {
            if (code === 0) {
                try {
                    root.info = JSON.parse(out);
                    root.failed = false;
                } catch (e) {
                    root.failed = true;
                }
            } else {
                root.failed = true;
            }
            root.applyVisibility();
        }, 0);
    }

    function checkNow() {
        if (root.checkCooling)
            return;
        root.checkCooling = true;
        cooldown.restart();
        // 30s cap: this is one API call, not the evaluation.
        Proc.runCommand("nixosUpdates.check", [root.scriptPath, "--check", "--force"], () => root.refresh(), 0, 30000);
    }

    onHideWhenIdleChanged: applyVisibility()

    // triggeredOnStart does the initial load, so no Component.onCompleted here —
    // PluginComponent already uses that hook to load pluginData.
    Timer {
        interval: root.pollSeconds * 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: cooldown
        interval: 60000
        onTriggered: root.checkCooling = false
    }

    // A raw Process, not Proc.runCommand: the dry-run evaluation takes ~a minute
    // and Proc's default timeout is 10s. `running` doubles as the busy flag.
    Process {
        id: diffProc
        command: [root.scriptPath, "--diff"]
        onExited: root.refresh()
    }

    pillRightClickAction: () => root.checkNow()

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: root.widgetThickness

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                DankIcon {
                    id: pillIcon
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.iconName
                    size: root.iconSize
                    color: root.tone
                    smoothTransform: root.isChecking

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                        running: root.isChecking

                        onRunningChanged: {
                            if (!running)
                                pillIcon.rotation = 0;
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.info.days + "d"
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Theme.widgetTextColor
                    visible: root.isOutdated && !root.isChecking
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: root.widgetThickness
            implicitHeight: root.widgetThickness

            DankIcon {
                id: vIcon
                anchors.centerIn: parent
                name: root.iconName
                size: root.iconSize
                color: root.tone
                smoothTransform: root.isChecking

                RotationAnimator on rotation {
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                    running: root.isChecking

                    onRunningChanged: {
                        if (!running)
                            vIcon.rotation = 0;
                    }
                }
            }
        }
    }

    popoutWidth: 420

    popoutContent: Component {
        PopoutComponent {
            headerText: "NixOS Updates"
            showCloseButton: true

            // The popout is the one place a stale answer is visible and
            // annoying, so re-read on open.
            Component.onCompleted: root.refresh()

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    width: parent.width
                    text: root.headline
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: root.failed ? Theme.error : Theme.surfaceText
                    wrapMode: Text.WordWrap
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: !root.failed && root.info.status !== "unknown"

                    Repeater {
                        model: [
                            {
                                "label": "Locked",
                                "date": root.info.current_date,
                                "rev": root.info.current_rev
                            },
                            {
                                "label": "Latest",
                                "date": root.info.latest_date,
                                "rev": root.info.latest_rev
                            }
                        ]

                        Row {
                            required property var modelData
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: modelData.date !== undefined && modelData.date !== ""

                            StyledText {
                                width: 56
                                text: parent.modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }

                            StyledText {
                                text: parent.modelData.date
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: root.shortRev(parent.modelData.rev)
                                font.pixelSize: Theme.fontSizeSmall
                                font.family: Theme.monoFontFamily
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                // The script evaluates against the very lock `nixup` would
                // write, so a failure here is a real answer — "your next nixup
                // will not build" — and gets said out loud rather than shown as
                // an empty package list.
                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.diffFailed

                    StyledText {
                        width: parent.width
                        text: "A rebuild would fail to evaluate"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.error
                    }

                    StyledText {
                        width: parent.width
                        text: root.diff.message
                        font.pixelSize: Theme.fontSizeSmall
                        font.family: Theme.monoFontFamily
                        color: Theme.surfaceVariantText
                        wrapMode: Text.WordWrap
                    }
                }

                Column {
                    id: diffSection
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.hasPackages || root.hasGroups

                    StyledText {
                        text: root.diff.count + (root.diff.count === 1 ? " package would change" : " packages would change")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankFlickable {
                        width: parent.width
                        height: Math.min(root.diff.count * 20 + 4, 240)
                        contentHeight: pkgColumn.implicitHeight
                        clip: true

                        Column {
                            id: pkgColumn
                            width: parent.width

                            Repeater {
                                model: root.diff.packages

                                StyledText {
                                    required property string modelData
                                    width: pkgColumn.width
                                    height: 20
                                    text: "• " + modelData
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.diffGroups

                        StyledText {
                            required property var modelData
                            width: diffSection.width
                            text: "+ " + modelData.count + " " + modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    text: "No package changes detected."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    visible: root.diff.fresh === true && root.diff.status === "empty"
                }

                Row {
                    spacing: Theme.spacingS

                    DankButton {
                        text: root.checkCooling ? "Checked" : "Check now"
                        enabled: !root.checkCooling
                        opacity: enabled ? 1 : 0.5
                        onClicked: root.checkNow()
                    }

                    DankButton {
                        text: diffProc.running ? "Evaluating…" : (root.diff.fresh ? "Refresh package list" : "Load package list")
                        enabled: !diffProc.running && root.isOutdated
                        opacity: enabled ? 1 : 0.5
                        onClicked: diffProc.running = true
                    }
                }

                StyledText {
                    width: parent.width
                    text: "Run nixup to update"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    visible: root.isOutdated
                }
            }
        }
    }
}
