# EEM Script to disable PoE on Cisco Catalyst Series Switches based on Interface description
---

[![published](https://static.production.devnetcloud.com/codeexchange/assets/images/devnet-published.svg)](https://developer.cisco.com/codeexchange/github/repo/pamosima/powersave)

Building and managing Cisco SD-Access fabric doesn't have to be challenging or complex! You just need to use the right approach and toolset. Terraform is an open-source infrastructure as code software tool created by HashiCorp. The dnacenter Terraform provider leverages the Cisco DNA Center APIs for managing and automating your Cisco DNA Center environment. This will reduce the overall time to create, change and delete fabric sites while delivering consistent outcomes of each fabric configuration step. This session will demonstrate step-by-step how to deploy a Cisco SD-Access fabric from scratch using Terraform together with Cisco DNA Center.

## The problem statements
At the moment, energy efficiency and sustainability are probably the number one topic across Europe or even worldwide. In general, the Cisco Catalyst 9000 Switches have multiple benefits regarding energy efficiency like platinum-rated power supply which are more efficient and lowering operating power costs or supporting features like Energy Efficient Ethernet (EEE) which is an IEEE 802.3az standard that is designed to reduce power consumption in Ethernet networks during idle periods.

However, there is not a single day a customer is asking how they can reduce the power consumption of their network. This led me to write [this](https://gblogs.cisco.com/ch-tech/energy-reduction-on-cisco-catalyst-series-switches/) blog post.

## The challenge
We started brainstorming in our team what we could do with our technology to help our customers. One idea was the optimized cooling of server or network cabinets with the help of [Cisco Meraki Sensors](https://meraki.cisco.com/sensors), another idea was to disable devices which are powered with PoE during off business hours. That’s exactly what I’m already doing at home for some of my APs. At home I’m using a simple Embedded Event Manager applet on my Catalyst Switch to disable PoE on all my switch ports. So I took that as a starting point. Let’s look at the Embedded Event Manager on the Catalyst Switches in general:

### Cisco IOS Embedded Event Manager
Cisco IOS ® Embedded Event Manager (EEM) is a unique subsystem within Cisco IOS Software. EEM is a powerful and flexible tool to automate tasks and customize the behavior of Cisco IOS Software and the operation of the device. Customers can use EEM to create and run programs or scripts directly on a router or switch. The scripts are referred to as EEM policies and can be programmed using a simple Command-Line-Interface (CLI)-based interface or using a scripting language called Tool Command Language (Tcl). EEM allows customers to harness the significant intelligence within Cisco IOS Software to respond to real-time events, automate tasks, create customized commands, and take local automated action based on conditions detected by the Cisco IOS Software itself.

## The Solution
Besides running scripts based on events it’s also possible to use cron job based event timers. This gives us the possibility to run a script at a specific time. My goal is to run a script at 7 pm to disable PoE on switch interfaces with a specific description. The reason for that could be that some of the interfaces still needs PoE for emergency phones. So in my example I decided to use the word of PowerSave in the interface description to disable PoE during off business. This brings me to the following EEM script:

`EnablePowerSave.tcl`
```
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
```

### Let’s look under the hood:

`event manager applet EnablePowerSave`  
this is the name of the applet

`event timer cron cron-entry "0 19 * * *"`  
This means the the applet will be triggered by a timer every day at 7 pm.

`action 1.0 set _interface_counter "0"`  
This will set variable _interface_counter to the value 0. I will use that to count the number of interfaces where PoE will be disabled.

`action 1.1 cli command “enable”`  
For the upcoming cli commands we need to be in enable mode.

`action 1.2 info type interface-names include "Ethernet"`  
To obtain interface names when an Embedded Event Manager (EEM) applet is triggered, use the action info type interface-names command in applet configuration mode. With the include command we can limit it to Ethernet interfaces and filter other interfaces like Loopback interfaces.

`action 1.3 foreach _interface "$_info_interface_names"`  
To specify the iteration of interface names using the delimiter as a tokenizing pattern.

`action 2.2 cli command “show run interface $_interface | i description”`  
`action 2.3 string match nocase “*PowerSave*” “$_cli_result”`  
`action 2.5 if $_string_result ge “1”`  
Using those actions to filter for interfaces with “PowerSave” in the description.

`action 3.1 cli command "conf t"`  
`action 3.2 cli command "interface $_interface"`  
`action 3.3 cli command "power inline never"`  
`action 3.4 cli command "end"`  
If the Value PowerSave was found we will disable PoE.

`action 3.5 increment _interface_counter 1`  
`action 3.6 end`  
`action 4 end`  
`action 4.1 puts "PoE disabled on $_interface_counter Interface(s) by PowerSaverEEM"`  
`action 4.2 syslog priority critical msg "PoE disabled on $_interface_counter Interface(s) by PowerSaverEEM"`  
Counting the number of interfaces where PoE gets disabled and send a message to the console and via syslog.

### Enabling PoE again
And on the other side at 7 am during weekdays I will enable PoE again:

`DisablePowerSave.tcl`
```
event manager applet DisablePowerSave
event timer cron cron-entry "0 7 * * 1-5"
action 1.1 cli command "enable"
action 1.2 info type interface-names include "Ethernet"
action 1.3 foreach _interface "$_info_interface_names"
action 2.2 cli command "show run interface $_interface | i description"
action 2.3 string match nocase "*PowerSave*" "$_cli_result"
action 2.4 puts "$_interface $_cli_result $_string_result"
action 2.5 if $_string_result ge "1"
action 3.1 cli command "conf t"
action 3.2 cli command "interface $_interface"
action 3.3 cli command "no power inline never"
action 3.4 cli command "end"
action 3.5 increment _interface_counter 1
action 3.6 end
action 4 end
action 4.1 puts "PoE enabled on $_interface_counter Interface(s) by PowerSaverEEM"
action 4.2 syslog priority critical msg "PoE enabled on $_interface_counter Interface(s) by PowerSaverEEM"
```

## Additional information
Both scripts can be deployed to your network with the help of Cisco DNA Center and a CLI template.


## Issues/Comments
Please post any issues or comments directly on GitHub.
