#!/bin/bash
set -e

prog=`basename $0`
archv=$1
temp=.${archv}-WALK-`date '+%Y%m%d-%H%M%S'`
taropt='-vS -z'

if [ -z "$1" ]; then
	echo "syntax: $prog ARCHIVE ">&2
	exit 1
fi

if [ -e $temp ]; then
	echo "$prog: File or folder $temp already exists!" >&2
	exit 1
fi

mv $archv $temp

echo "$prog: unpacking archive"
mkdir -m 0700 $archv
cd $archv
tar $taropt -xf ../$temp

echo "$prog: starting new shell"
bash -i
echo "$prog: shell terminated."

read -p "$prog: Recreate archive $archv ? [Y/n] " recreate
case $recreate in
	y|Y|"")
	echo "$prog: recreating archive"
	tar $taropt -cf ../$temp .
	;;
esac

cd ..

read -p "$prog: Delete temporary directory? [Y/n] " deltemp
case $deltemp in
	y|Y|"")
		echo "$prog: deleting temp dir"
		rm -rf $archv
		;;
	*)
		save="${archv}-`date +'%Y%m%d-%H%M'`"
		echo "$prog: renaming temp dir to $save"
		mv $archv $save
		;;
esac

mv $temp $archv
