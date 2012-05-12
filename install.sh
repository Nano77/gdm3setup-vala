#! /bin/sh
#
#

#Ubuntu
#chown -R gdm:gdm /var/lib/gdm/

#Ubuntu/Debian
#sed -i s/python2/python/ gdmlogin.py

#Debian
#sed -i -e 's/sbin\/gdm/sbin\/gdm3/' gdm3setup-daemon.vala
#sed -i -e 's/sbin\/gdm/sbin\/gdm3/' gdm3setup.vala
#sed -i -e 's/etc\/gdm/etc\/gdm3/' gdm3setup-daemon.vala
#sed -i -e 's/etc\/gdm/etc\/gdm3/' gdmlogin.py
#sed -i -e 's/"gdm"/"Debian-gdm"/' gdm3setup-daemon.vala

valac --pkg gtk+-3.0 --pkg gio-2.0 --pkg gnome-desktop-3.0 --pkg gdk-3.0 -X -D'GETTEXT_PACKAGE="gdm3setup"' gdm3setup.vala --disable-warnings
valac --pkg gio-2.0 gdm3setup-daemon.vala --disable-warnings

cd po
./make-mo
cd ..

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
install -D gdm3setup.ui /usr/share/gdm3setup/ui/gdm3setup.ui
cp -r locale /usr/share/
