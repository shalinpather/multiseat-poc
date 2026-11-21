divert(-1)
SPDX-License-Identifier: 0BSD

xorg.conf.m4
X.Org Configuration template for the single-GPU multiseat proof-of-concept.

Shalin Pather
shalin.pather01@gmail.com
2026/11/21

Usage:
echo 'CONF(<N>, <kbd>, <mouse>)' | m4 xorg.conf.m4 -

- N: number of the current seat (whole number)
- kbd: path to evdev keyboard device node
- mouse: path to evdev mouse device node

define(`CONF', `dnl
Section "ServerFlags"
	Option "AllowEmptyInput" "True"
	Option "AutoAddDevices" "False"
	Option "AutoAddGPU" "False"
	Option "DontVTSwitch" "True"
EndSection

Section "Device"
	Identifier "Card0"
	Driver "modesetting"
	Option "kmsdev" "seat$1"
	Screen 0
EndSection

Section "Screen"
	Identifier "Screen0"
	Device "Card0"
EndSection

dnl We must bypass autoconfiguration and races against udev and logind.
dnl Edit these input sections to set more options as required.
Section "InputDevice"
	Identifier "Keyboard"
	Driver "evdev"
	Option "Device" "$2"
	Option "GrabDevice" "on"
EndSection

Section "InputDevice"
	Identifier "Mouse"
	Driver "evdev"
	Option "Device" "$3"
	Option "GrabDevice" "on"
EndSection

Section "ServerLayout"
	Identifier "Layout0"
	Screen "Screen0"
	InputDevice "Keyboard" "CoreKeyboard"
	InputDevice "Mouse" "CorePointer"
EndSection`'dnl
')

divert(0)dnl
