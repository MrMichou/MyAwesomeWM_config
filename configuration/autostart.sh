#!/bin/sh

start() {
  if ! pgrep -f "$1" ;
  then
    "$@"&
  fi
}

start /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
start nm-applet
start blueman-applet
start redshift -l -19:-65
#start picom --config=$HOME/.config/awesome/theme/picom.conf
#start diodon
start fusuma -d
start ulauncher --daemon
#start easyeffects --gapplication-service
