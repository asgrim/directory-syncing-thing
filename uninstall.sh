#!/bin/bash
#
# Copyright (C) 2011 James Titcumb
#
# See LICENSE file for license!
#

if [ $UID != 0 ]
then
  echo "This script must be run as root."
  exit 1
fi

source dst-install-conf

if [ -f $CONFIGFILE ]
then
  echo "Leaving $CONFIGFILE in situ. Remove manually..."
fi

if [ -f $INITSCRIPT ]
then
  rm -v $INITSCRIPT
fi

INITFILES=`ls /etc/rc*.d/*directory-syncing-thing 2> /dev/null`
for F in $INITFILES
do
  rm -v $F
done

echo "Uninstall complete."
