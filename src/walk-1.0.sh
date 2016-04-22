#!/bin/bash
set -e

#  Copyright (C) 2010  Maximilian L. Eul
#  This file is part of walk.
#
#  walk is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  walk is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with walk.  If not, see <http://www.gnu.org/licenses/>.


prog=`basename $0`
archv=$1
temp=".${archv}-WALK-"`date '+%Y%m%d-%H%M%S'`

# Check arguments
if [ -z "$1" ]; then
	echo "syntax: $prog ARCHIVE ">&2
	exit 1
fi
if [ -e $temp ]; then
	echo "$prog: File or folder $temp already exists!" >&2
	exit 2
fi


tartype () {
	case "$1" in
		*"gz"*" compressed"*)  # gzip
			taropt="$taropt_gzip $taropt"
			;;
		*"bz"*"2 compressed"*)  # bz2
			taropt="$taropt_bzip2 $taropt"
			;;
		*"("*|*"compr"*|*"extract"*)  # unknown
			return 1
			;;
		*)  # plain tar
			;;
	esac
	return 0
}

usearchv="../${temp}"
call_pack=
call_unpack=
verify=
archvtype () {
	ft=`file -Nbz $archv 2>/dev/null | tr \'[A-Z]\' \'[a-z]\'` || return 1


	case "$ft" in
		*"tar archive"*)
			taropt="--same-owner -spvSf $usearchv"
			taropt_gzip='-z'
			taropt_bzip2='-j'
			tartype "$ft" || return 2
			call_unpack="tar -x $taropt"
			call_pack="tar -c $taropt ."
			;;
		*"rar archive"*)
			raropt="-o+ -ol -ow -r -r0 -tl $usearchv"
			call_unpack="rar e $raropt"
			call_pack="rar u $raropt ."
			;;
		*"zip archive"*)
			zipopt="-v $usearchv"
			call_unpack="UNZIP= unzip -o -X $zipopt"
			call_pack="ZIP= ZIPOPT= zip -u -y -R $zipopt ."
			;;
		*"cpio archive"*)
			cpioopt="-v -B -F $usearchv"
			call_unpack="cpio -i -d --no-absolute-filenames --sparse $cpioopt"
			call_pack="find -mindepth 1 | cpio -o -H crc $cpioopt"
			;;
		*" ar archive"*)
			aropt="sv"
			call_unpack="ar x${aropt} $usearchv"
			call_pack="find -mindepth 1 | xargs ar r${aropt} $usearchv"
			;;
		*)
			return 1
			;;
	esac
	return 0
}

#####################################################################


# Determine archive file type
if ! archvtype; then
	echo "$prog: unknown archive file type!" >&2
	exit 3
fi

#echo "  PACK: $call_pack"
#echo "UNPACK: $call_unpack"
#exit

# Rename archive file
mv $archv $temp

# Unpack archive
echo "$prog: unpacking archive"
mkdir -m 0700 $archv
cd $archv
eval "$call_unpack"

# Start walking shell
echo "$prog: starting new shell"
bash -i  || true
echo "$prog: shell terminated."
eval
# Repack archive
read -p "$prog: Recreate archive $archv ? [Y/n] " recreate
case $recreate in
	y|Y|"")
	echo "$prog: recreating archive"
	eval "$call_pack"
	;;
esac

# Clean up
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

# fin
exit 0


