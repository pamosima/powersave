
# Copyright (c) 2023 Cisco and/or its affiliates.

# This software is licensed to you under the terms of the Cisco Sample
# Code License, Version 1.1 (the "License"). You may obtain a copy of the
# License at

#                https://developer.cisco.com/docs/licenses

# All use of the material herein must be in accordance with the terms of
# the License. All rights not expressly granted by the License are
# reserved. Unless required by applicable law or agreed to separately in
# writing, software distributed under the License is distributed on an "AS
# IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied.

event manager applet EnablePowerSave
event timer cron cron-entry "0 19 * * *"
action 1.0 set _interface_counter "0"
action 1.1 cli command "enable"
action 1.2 info type interface-names include "Ethernet"
action 1.3 foreach _interface "$_info_interface_names"
action 2.2 cli command "show run interface $_interface | i description"
action 2.3 string match nocase "*PowerSave*" "$_cli_result"
action 2.5 if $_string_result ge "1"
action 3.1 cli command "conf t"
action 3.2 cli command "interface $_interface"
action 3.3 cli command "power inline never"
action 3.4 cli command "end"
action 3.5 increment _interface_counter 1
action 3.6 end
action 4 end
action 4.1 puts "PoE disabled on $_interface_counter Interface(s) by PowerSaverEEM"
action 4.2 syslog priority critical msg "PoE disabled on $_interface_counter Interface(s) by PowerSaverEEM"
