#!/bin/bash
#
# Copyright (C) 2011 James Titcumb
#
# See LICENSE file for license!
#

CONFIGFILE=/etc/directory-syncing-thing.conf
INITSCRIPT=/etc/init.d/directory-syncing-thing
if [ $UID != 0 ]
then
  echo "This script must be run as root."
  exit 1
fi

if [ -f $CONFIGFILE ]
then
  echo "You already have a config file, not going to overwrite it... you may want to merge changes."
else
  echo "Copy example config to $CONFIGFILE."
  echo "DON'T FORGET TO MODIFY THIS BEFORE RUNNING IT..."
  cp directory-syncing-thing.conf.example $CONFIGFILE
fi

if [ -f $INITSCRIPT ]
then
  echo "Init script already exists, not going to overwrite it."
else
  echo "Softlink directory-syncing-thing in the init.d directory"
  ln -s /opt/directory-syncing-thing/directory-syncing-thing $INITSCRIPT
fi
