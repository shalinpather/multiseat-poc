divert(-1)
SPDX-License-Identifier: 0BSD

run-seat.sh.m4
Multiseat startup template for the single-GPU multiseat proof-of-concept.

Shalin Pather
shalin.pather01@gmail.com
2026/11/21

Usage:
printf "CONF(<N_1>, <ses_1>)\nCONF(<N_2>, <ses_2>)\n..." | m4 run-seat.sh.m4

- N: number of the current seat (whole number)
- ses: desktop session (e.g., `mate-session', `openbox-session', `i3', etc.)

define(`CONF', `dnl
X :$1 -nolisten tcp -config /etc/X11/xorg-seat$1.conf -logfile /var/log/xorg-seat$1.log -sharevts -novtswitch &

dnl Wait on X server
i=0
while [ ! -S "/tmp/.X11-unix/X$1" ]; do
	i=$((i + 1))
	[ "$i" -ge 30 ] && exit 1
	sleep 0.2
done

DISPLAY=:$1 xhost +SI:localuser:seat$1
su - seat$1 -c "DISPLAY=:$1 dbus-run-session $2" &
')

divert(0)dnl
#!/bin/sh
set -eu

if [ "$(id -u)" -ne 0 ]
then
	echo 'Error: this script must be run as root.' >&2
	exit 1
fi

drm-lease-manager &
sleep 1

dnl Seat configurations
include(/dev/stdin)

wait
