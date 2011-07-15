#!/bin/bash

#
# Copyright (C) 2011 James Titcumb
#
# See LICENSE file for license!
#

SYNC_LOCAL_DIR=$1
SYNC_REMOTE_DIR=$2
LABEL=$3

cd $SYNC_LOCAL_DIR
CURPATH=`pwd`
echo $CURPATH

source /etc/directory-syncing-thing.conf

if [ "$WAITFORREMOTEMOUNT" == "Yes" ]
then
  MOUNTED=false
  echo -ne "Waiting for mount [$REMOTEDIR] to become available.."

  while [ $MOUNTED != "true" ]
  do
    echo -ne "."
    sleep 10
    if grep -q "[[:space:]]$REMOTEDIR[[:space:]]" /proc/mounts
    then
      MOUNTED=true
    fi
  done
  echo "Mounted"
fi

if [ "$UNISONINITIALSYNC" == "Yes" ]
then
  echo -ne "Running initial sync... "
  unison default $SYNC_LOCAL_DIR $SYNC_REMOTE_DIR -batch -silent -auto -ui text -perms 0 >/dev/null 2>&1
  echo "done"
fi

inotifywait -rm --exclude '.tmp$' --exclude '.lock$' --format "%e:%w:%f" $SYNC_LOCAL_DIR -e MODIFY,MOVE,CREATE,DELETE | while read FILE
do
	BITS=(`echo $FILE | tr ':' '\n'`)
	ACTION=${BITS[0]}
	WATCH=${BITS[1]}
	FILE=${BITS[2]}

	FILECHANGED=`echo "${WATCH}${FILE}" | sed 's_'$CURPATH'/__'`

	echo -ne "$LABEL [$ACTION $FILECHANGED] "

	case $ACTION in
		'MODIFY' | 'MOVED_TO' | 'CREATE')
			cp $SYNC_LOCAL_DIR/$FILECHANGED $SYNC_REMOTE_DIR/$FILECHANGED
			echo "Copied $SYNC_LOCAL_DIR/$FILECHANGED to $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'DELETE' | 'MOVED_FROM')
			rm $SYNC_REMOTE_DIR/$FILECHANGED
			echo "Removed $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'CREATE,ISDIR')
			mkdir $SYNC_REMOTE_DIR/$FILECHANGED
			echo "Created $SYNC_REMOTE_DIR/$FILECHANGED directory"
			;;
		'DELETE,ISDIR')
			rm -Rf $SYNC_REMOTE_DIR/$FILECHANGED
			echo "Deleted $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		*)
			echo "Action [$ACTION] not supported yet."
			;;
	esac
done
