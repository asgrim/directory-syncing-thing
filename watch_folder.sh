#!/bin/bash

# Copyright (c) 2011 James Titcumb
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
