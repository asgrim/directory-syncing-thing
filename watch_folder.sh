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
  echo -ne "Waiting for mount [$REMOTEDIR] to become available.."

  while true
  do
    if grep -q "[[:space:]]$REMOTEDIR[[:space:]]" /proc/mounts
    then
      break
    fi
    echo -ne "."
    sleep 10
  done
  echo "Mounted"
fi

if [ "$UNISONINITIALSYNC" == "Yes" ]
then
  echo -ne "Running initial sync... "
  unison default $SYNC_LOCAL_DIR $SYNC_REMOTE_DIR -batch -silent -auto -ui text -perms 0 >/dev/null 2>&1
  echo "done"
fi

IFS=':'
inotifywait -rm --exclude '.tmp$' --exclude '.lock$' --format "%e:%w:%f" $SYNC_LOCAL_DIR -e MODIFY,MOVE,CREATE,DELETE | \
while read ACTION WATCH FILE
do
	FILECHANGED="${WATCH#$CURPATH/}${FILE}"

	echo -e "$LABEL [$ACTION $FILECHANGED]"

	case $ACTION in
		'MODIFY' | 'MOVED_TO' | 'CREATE')
			mkdir -p $SYNC_REMOTE_DIR/${FILECHANGED%/*}
			cp $SYNC_LOCAL_DIR/$FILECHANGED $SYNC_REMOTE_DIR/$FILECHANGED
			echo -e "  Copied\n    $SYNC_LOCAL_DIR/$FILECHANGED\n    $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'DELETE' | 'MOVED_FROM')
			rm $SYNC_REMOTE_DIR/$FILECHANGED
			echo -e "  Removed\n    $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'CREATE,ISDIR')
			mkdir $SYNC_REMOTE_DIR/$FILECHANGED
			echo -e "  Create directory\n    $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'DELETE,ISDIR' | 'MOVED_FROM,ISDIR')
			rm -Rf $SYNC_REMOTE_DIR/$FILECHANGED
			echo -e "  Delete directory\n    $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		'MOVED_TO,ISDIR')
			cp -af $SYNC_LOCAL_DIR/$FILECHANGED $SYNC_REMOTE_DIR/$FILECHANGED
			echo -e "  Copy directory $SYNC_REMOTE_DIR/$FILECHANGED"
			;;
		*)
			echo "  Action [$ACTION] not supported yet."
			;;
	esac
done
