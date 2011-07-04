#!/bin/bash

#
# Copyright (C) 2011 James Titcumb
#
# See LICENSE file for license!
#

LOCALDIR=$1
REMOTEDIR=$2
LABEL=$3

cd $LOCALDIR
CURPATH=`pwd`
echo $CURPATH

# rsync -rv $LOCALDIR $REMOTEDIR

echo -ne "Running initial sync... "
unison default $LOCALDIR $REMOTEDIR -batch -silent -auto -ui text -perms 0 >/dev/null 2>&1
# unison default $LOCALDIR $REMOTEDIR -batch -auto -ui text -perms 0
echo "done"

inotifywait -rm --exclude '.tmp$' --exclude '.lock$' --format "%e:%w:%f" $LOCALDIR -e MODIFY,MOVE,CREATE,DELETE | while read FILE
do
	BITS=(`echo $FILE | tr ':' '\n'`)
	ACTION=${BITS[0]}
	WATCH=${BITS[1]}
	FILE=${BITS[2]}

	FILECHANGED=`echo "${WATCH}${FILE}" | sed 's_'$CURPATH'/__'`

	echo -ne "$LABEL [$ACTION $FILECHANGED] "

	case $ACTION in
		'MODIFY' | 'MOVED_TO' | 'CREATE')
			cp $LOCALDIR/$FILECHANGED $REMOTEDIR/$FILECHANGED
			echo "Copied $LOCALDIR/$FILECHANGED to $REMOTEDIR/$FILECHANGED"
			;;
		'DELETE' | 'MOVED_FROM')
			rm $REMOTEDIR/$FILECHANGED
			echo "Removed $REMOTEDIR/$FILECHANGED"
			;;
		'CREATE,ISDIR')
			mkdir $REMOTEDIR/$FILECHANGED
			echo "Created $REMOTEDIR/$FILECHANGED directory"
			;;
		'DELETE,ISDIR')
			rm -Rf $REMOTEDIR/$FILECHANGED
			echo "Deleted $REMOTEDIR/$FILECHANGED"
			;;
		*)
			echo "Action [$ACTION] not supported yet."
			;;
	esac
done
