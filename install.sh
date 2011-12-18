#! /bin/sh
#
#

valac --pkg gtk+-3.0 --pkg gio-2.0 -X -D'GETTEXT_PACKAGE="gdm3setup"' gdm3setup.vala --disable-warnings
valac --pkg gio-2.0 gdm3setup-daemon.vala --disable-warnings

install --mode=755 -D gdm3setup /usr/bin/
install --mode=755 -D gdm3setup-daemon /usr/bin/
install --mode=755 -D gdmlogin.py /usr/bin/
install --mode=755 -D get_gdm.sh /usr/bin/
install --mode=755 -D set_gdm.sh /usr/bin/
install -D gdm3setup.desktop /usr/share/applications/
install -D apps.nano77.gdm3setup.service /usr/share/dbus-1/system-services/
install -D apps.nano77.gdm3setup.service /usr/share/dbus-1/services/
install -D apps.nano77.gdm3setup.conf /etc/dbus-1/system.d/
install -D apps.nano77.gdm3setup.policy /usr/share/polkit-1/actions/
cp -r locale /usr/share/
