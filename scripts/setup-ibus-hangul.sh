#!/bin/bash

# install packages
sudo pacman -S ibus ibus-hangul

# create config
XPROFILE=$(cat <<-END
export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus
ibus-daemon -drx
END)
echo $XPROFILE > ~/.xprofile
source ~/.xprofile

# setup input method, shortcurt
ibus-setup
