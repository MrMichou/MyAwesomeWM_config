#!/bin/sh

start() {
  if ! pgrep -f "$1" ;
  then
    "$@"&
  fi
}

start /usr/lib/polkit-kde-authentication-agent-1
start nm-applet
start blueman-applet
# LATITUDE/LONGITUDE come from configuration/variables.lua (see rc.lua)
[ -n "$LATITUDE" ] && start redshift -l "$LATITUDE:$LONGITUDE"
#start picom --config=$HOME/.config/awesome/theme/picom.conf
#start diodon
start fusuma -d
start ulauncher --daemon
#start easyeffects --gapplication-service
