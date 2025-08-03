#!/usr/bin/env python
from openrazer.client import DeviceManager

device_manager = DeviceManager()

viper = None

for device in device_manager.devices:
    if "Razer Viper Ultimate (Wireless)" == device.name:
        viper = device

if None == viper:
    print('')
    exit()

icon = ''
battery_level = viper.battery_level
cssClass = ''
if viper.is_charging or battery_level == 0:
    cssClass = 'charging'
    icon = '󰍿'
    content = (" {} ".format(icon))
    print("{\"text\": \"" + content + "\", \"class\": \"" + cssClass + "\"}")
    exit()
else:
    if battery_level <= 50:
        cssClass = 'warning'
        if battery_level < 15:
            cssClass = 'alert'
    else:
        cssClass = 'battery'

    content = (" {} {}%".format(icon, viper.battery_level))
    print("{\"text\": \"" + content + "\", \"class\": \"" + cssClass + "\"}")
    exit()
