#!/bin/sh
# SPDX-License-Identifier: 0BSD

# install.sh
# Master install script for single-GPU multiseat proof-of-concept.

# Shalin Pather
# shalin.pather01@gmail.com
# 2026/11/21

# Usage
# ./install.sh

# WARNING:
# This setup script is NOT idempotent and assumes a clean install of Debian
# Trixie (13). It makes destructive changes such as clobbering files and
# modifying system services. It should be run on an expendable test PC, not a
# daily-use machine. It is also useful to set up a serial (UART/RS-232) console
# or SSH for out-of-band management as this setup directly hinders the ability
# of normal graphical management from a GUI or VT subsystem, should it crash.

# NOTE:
# This script records the configuration required for the author's test setup,
# including connectors and peripherals, rather than attempting to be an all-in-
# one setup wizard. Adjust this script to your own needs. All adjustable
# sections are marked with `ADJUST:' comments for easy finding.


set -eu

if [ "$(id -u)" -ne 0 ]
then
	echo 'Error: this script must be run as root.' >&2
	exit 1
fi


# Configuration

# ADJUST: change target to aarch64-linux-gnu if building on a Raspberry Pi, or
# whatever other target is required.

TARGET="x86_64-linux-gnu"

# ADJUST: specify the package name of the preferred desktop, e.g.,
# `mate-desktop-environment' or `openbox'. This assumes the relevant
# package was not already installed using the Debian installer disk.

PACKAGE="mate-desktop-environment"

# ADJUST: choose a preferred desktop session, e.g., `mate-session' or
# `openbox-session'.

SESSION="mate-session"

# ADJUST: find the keyboard and mouse ID from /dev/input. By plugging in each
# device, one at a time, it is possible to use the most recent output from the
# `dmesg' command to see the address of each device.

# NOTE: as the reference configuration only uses two seats, this script is
# hardcoded for two seats, rather than using arrays. Thus, it is necessary
# to edit the sections where these variables are referenced. This is in line
# with the non-genericity goal of this proof-of-concept. All the relevant
# sections are clearly marked with `ADJUST'.

SEAT0_CON="HDMI-A-1"
SEAT0_KBD="/dev/input/by-id/usb-DELL_Dell_USB_Entry_Keyboard-event-kbd"
SEAT0_MOUSE="/dev/input/by-id/usb-30fa_USB_OPTICAL_MOUSE-event-mouse"

SEAT1_CON="VGA-1"
SEAT1_KBD="/dev/input/by-id/usb-CASUE_CASUE_USB_Keyboard-event-kbd"
SEAT1_MOUSE="/dev/input/by-id/usb-Genius_Optical_Mouse-event-mouse"

# Seat user setup
# ===============

# ADJUST: set friendlier usernames and passwords if needed.
# Perform this action here to let the remainder of the installation complete
# unattended.

# $1: seat number
create_user() {
	if ! id "seat$1" > /dev/null 2>&1
	then
		useradd -m "seat$1"
	fi
}

# ADJUST: add more seat users if needed.

create_user 0
create_user 1

# Build and runtime dependencies
# ==============================

# Ensure source repositories are available (both DEB822 and legacy formats).
if [ -f /etc/apt/sources.list.d/debian.sources ]
then
	sed -i 's/^Types: deb$/Types: deb deb-src/' \
		/etc/apt/sources.list.d/debian.sources
fi

if [ -f /etc/apt/sources.list ]
then
	sed -i 's/^# *deb-src /deb-src /' /etc/apt/sources.list
fi

# Main installation
# =================

apt-get update -y
apt-get upgrade -y
apt-get install -y \
	$PACKAGE \
	build-essential \
	dbus-x11 \
	git \
	libdrm-dev \
	libtirpc-dev \
	m4 \
	meson \
	ninja-build \
	pkg-config \
	x11-xserver-utils \
	xserver-xorg-core \
	xserver-xorg-input-evdev

apt build-dep -y xorg-server

mkdir -p src && cd src

# tomlc99 (config parser)
# =======================

git clone https://github.com/cktan/tomlc99.git
cd tomlc99
make
make install prefix=/usr/local
# This step should be done by `make install', but was forgot.
mkdir -p /usr/local/lib/pkgconfig
cp libtoml.pc.sample /usr/local/lib/pkgconfig/libtoml.pc
ldconfig
cd ..

if ! PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
	pkg-config --exists libtoml > /dev/null 2>&1
then
	echo 'Error: libtoml not installed correctly.' >&2
	exit 1
fi

# DRM Lease Manager
# =================

git clone https://github.com/AGLExport/drm-lease-manager.git
cd drm-lease-manager
PKG_CONFIG_PATH=/usr/local/lib/pkgconfig meson setup build --prefix=/usr/local
meson compile -C build
meson install -C build
ldconfig
cd ..

if ! PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
	pkg-config --modversion libdlmclient > /dev/null 2>&1
then
	echo 'Error: DRM Lease Manager not installed correctly.' >&2
	exit 1
fi

# Patched X.Org server
# ====================

mkdir -p xorg && cd xorg
apt source xorg-server
cd xorg-server-*

if ! patch -p1 --dry-run < ../../../xserver_multiseat.patch > /dev/null 2>&1
then
	echo 'X.Org server patch failed.' >&2
	exit 1
fi

patch -p1 < ../../../xserver_multiseat.patch

# Strictly, we don't need the udev and suid functionality. At least, we keep
# udev to remain close to standard Debian X.Org without causing races during
# device enumeration (despite avoiding autoconfiguration). Installing the full
# custom X.Org build, rather than just the drivers, might mitigate this.

PKG_CONFIG_PATH=/usr/local/lib/pkgconfig meson setup build-custom \
	--prefix=/usr \
	--sysconfdir=/etc \
	--localstatedir=/var \
	"--libdir=lib/${TARGET}" \
	"-Dmodule_dir=lib/${TARGET}/xorg/modules" \
	-Dxorg=true \
	-Dglamor=true \
	-Dudev=true \
	-Dsystemd_logind=false \
	-Dsuid_wrapper=false

meson compile -C build-custom

if ! ldd build-custom/hw/xfree86/drivers/modesetting/modesetting_drv.so \
	| grep -q dlmclient
then
	echo 'Error: modesetting driver did not link against libdlmclient.' >&2
	exit 1
fi

# WARNING: This section overwrites the modesetting and Glamor modules on the
# system. If porting this script, ensure to build these modules with the same
# ABI as the host's X server. This operation can be made non-destructive by
# commenting this section out and passing -modulepath explicitly to the X
# server. Alternatively, if there is an ABI mismatch between the host X server
# and the custom patched X server, consider installing the X server binary as
# well, or simply passing the -ignoreABI option (risky).

# Back up old modules.

[ ! -f /usr/lib/xorg/modules/drivers/modesetting_drv.so.bak ] \
	&& cp /usr/lib/xorg/modules/drivers/modesetting_drv.so \
	/usr/lib/xorg/modules/drivers/modesetting_drv.so.bak

[ ! -f /usr/lib/xorg/modules/libglamoregl.so.bak ] \
	&& cp /usr/lib/xorg/modules/libglamoregl.so \
	/usr/lib/xorg/modules/libglamoregl.so.bak

# Install new modules.

cp build-custom/hw/xfree86/drivers/modesetting/modesetting_drv.so \
	/usr/lib/xorg/modules/drivers/
chmod 0755 /usr/lib/xorg/modules/drivers/modesetting_drv.so
cp build-custom/hw/xfree86/glamor_egl/libglamoregl.so /usr/lib/xorg/modules/
chmod 0755 /usr/lib/xorg/modules/libglamoregl.so

cd ../../..

# Post-installation multiseat configuration
# =========================================

# DRM Lease Manager configuration

touch /etc/drm-lease-manager.toml
chmod 644 /etc/drm-lease-manager.toml

# ADJUST: Add as many DRM leases as needed per seat.
echo "CONF(0, ${SEAT0_CON})" | m4 drm-lease-manager.toml.m4 - \
	> /etc/drm-lease-manager.toml
echo "CONF(1, ${SEAT1_CON})" | m4 drm-lease-manager.toml.m4 - \
	>> /etc/drm-lease-manager.toml

# X server configuration

# ADJUST: Add as many X server configurations as needed per seat.
echo "CONF(0, ${SEAT0_KBD}, ${SEAT0_MOUSE})" | m4 xorg.conf.m4 - \
	> /etc/X11/xorg-seat0.conf
echo "CONF(1, ${SEAT1_KBD}, ${SEAT1_MOUSE})" | m4 xorg.conf.m4 - \
	> /etc/X11/xorg-seat1.conf

# Systemd service configuration

mkdir -p /usr/local/sbin
touch /usr/local/sbin/run-seat.sh
chmod 744 /usr/local/sbin/run-seat.sh

# ADJUST: Add as many seats as necessary.
printf "CONF(0, ${SESSION})\nCONF(1, ${SESSION})\n" \
	| m4 run-seat.sh.m4 - > /usr/local/sbin/run-seat.sh

# Copy the service file without header comments.

touch /etc/systemd/system/multiseat.service
chmod 644 /etc/systemd/system/multiseat.service
sed '/^#/d;/^$/d' < multiseat.service > /etc/systemd/system/multiseat.service

# Finalise the setup.

# ADJUST: specify another display manager here.
systemctl disable --now gdm lightdm sddm > /dev/null 2>&1 || true
systemctl enable multiseat
systemctl daemon-reload
