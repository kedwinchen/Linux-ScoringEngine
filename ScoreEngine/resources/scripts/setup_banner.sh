#!/bin/bash

source /opt/ScoreEngine/master_se_functions.sh
set_vars

git clone https://github.com/fcaviggia/classification-banner.git banner

cp banner/classification-banner.py /usr/local/bin/classification-banner.py

cat <<- _EOF_ > /etc/classification-banner.template

	show_bottom=False
	sys_info=True
	spanning=False
	message='%FRACTION% VULNERABILITIES FOUND'
	bgcolor='%BGCOLOR%'
	fgcolor='#000000'

_EOF_

cat <<- _EOF_ > /etc/classification-banner

	show_bottom=False
	sys_info=True
	spanning=False
	message='SCORING NOT YET INITIALIZED'
	bgcolor='#FF0000'
	fgcolor='#000000'

_EOF_

chmod 644 /etc/classification-banner*
chown root:root /etc/classification-banner*

cat <<- _EOF_ > /etc/xdg/autostart/classification-banner.desktop
	[Desktop Entry]
	Name=Classification Banner
	Exec=/usr/bin/python2 /usr/local/bin/classification-banner.py
	Comment=User Notification for Security Level of System.
	Type=Application
	Encoding=UTF-8
	Version=1.0
	MimeType=application/python;
	Categories=Utility;
	X-GNOME-Autostart-enabled=true
	StartupNotify=false
	Terminal=false
_EOF_

chown root:root /etc/xdg/autostart/classification-banner.desktop
chmod 644 /etc/xdg/autostart/classification-banner.desktop
