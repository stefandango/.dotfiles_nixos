import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "headsetBattery"

    StyledText {
        width: parent.width
        text: "Headset Battery"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Medium
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Reads `headsetcontrol -b -o json`. Needs its udev rules (services.udev.packages) or every read fails on hidraw permissions."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "pollSeconds"
        label: "Poll interval"
        description: "How often to ask the headset for its battery level"
        defaultValue: 60
        minimum: 15
        maximum: 600
        unit: "s"
        leftIcon: "schedule"
    }

    ToggleSetting {
        settingKey: "notifyLow"
        label: "Low battery notification"
        description: "Notify once when the level drops below the threshold"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "lowThreshold"
        label: "Low battery threshold"
        description: "Turn the pill red and notify below this level"
        defaultValue: 15
        minimum: 5
        maximum: 50
        unit: "%"
        leftIcon: "battery_alert"
    }
}
