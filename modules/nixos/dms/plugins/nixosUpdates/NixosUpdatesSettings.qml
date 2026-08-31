import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "nixosUpdates"

    StyledText {
        width: parent.width
        text: "NixOS Updates"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Reads ~/Scripts/nixupdates. The nixpkgs branch tip is fetched at most once every four hours regardless of the poll interval below, so this is cheap to leave running."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    ToggleSetting {
        settingKey: "hideWhenIdle"
        label: "Hide when up to date"
        description: "Collapse the pill when the lock matches the branch tip"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "pollSeconds"
        label: "Poll interval"
        description: "How often to re-read the cached verdict"
        defaultValue: 600
        minimum: 60
        maximum: 3600
        unit: "s"
        leftIcon: "schedule"
    }
}
