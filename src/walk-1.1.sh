#!/bin/bash
set -e

#  walk v1.1
#  
#  Copyright (C) 2012  Maximilian L. Eul
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


base=`pwd`
prog=`basename $0`
archv=$1
temp=".${archv}-WALK-"`date '+%Y%m%d-%H%M%S'`

# Check arguments
if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "syntax: $prog ARCHIVE "
	echo ""
	echo "walk v1.1 will unpack an archive file into a new directory of the"
	echo "same name and spawn a new shell within that directory. After said"
	echo "shell terminates, walk will ask you whether you want to re-create"
	echo "the archive from that directory and whether you want to delete the"
	echo "temporary directory."
	echo ""
	echo "Recognized archive types:"
	echo " - tar, tar.gz, tar.bz2, tar.xz (requires tar with built-in compression support)"
	echo " - 7-zip (requires 7zr)"
	echo " - zip (requires zip/unzip)"
	echo " - rar (requires rar)"
	echo " - cpio, ar"
	echo ""
	exit 0
fi
if [ -z "$1" ]; then
	echo "syntax: $prog ARCHIVE ">&2
	exit 1
fi
if [ ! -e "$1" ]; then
	echo "$prog: $1 not found" >&2
fi
if [ -e "$1" -a ! -f "$1" ]; then
	echo "$prog: $1 is not a file" >&2
fi
if [ -e $temp ]; then
	echo "$prog: File or folder $temp already exists!" >&2
	exit 2
fi

tartype () {
	case "$1" in
		*"(gz"*" compressed"*)  # gzip
			taropt="$taropt_gzip $taropt"
			;;
		*"(bz"*"2 compressed"*)  # bz2
			taropt="$taropt_bzip2 $taropt"
			;;
		*"(XZ"*" compressed"*)  # xz
			taropt="$taropt_xz $taropt"
			;;
		*"GNU"*") ("*|*"compr"*|*"extract"*)  # unknown
			echo UNKN TAR
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

archvtype () {
	ft=`file -Nbz $archv 2>/dev/null | tr \'[A-Z]\' \'[a-z]\'` || return 1

	case "$ft" in
		*"tar archive"*)
			taropt="--same-owner -spvSf $usearchv"
			taropt_gzip='-z'
			taropt_bzip2='-j'
			taropt_xz='-J'
			tartype "$ft" || return 2
			call_unpack="tar -x $taropt"
			call_pack="tar -c $taropt ."
			;;
		"7-zip archive"*)
			z7opt="-bd -ms=on $usearchv"
			call_unpack="7zr e ${z7opt}"
			call_pack="7zr a ${z7opt} ."
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
			call_pack="find -print0 -mindepth 1 | cpio -0 -o -H crc $cpioopt"
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
cd $base/$archv
$call_unpack

# Start walking shell
echo "$prog: starting new shell"
unset IGNOREEOF
${SHELL:-'/bin/bash'} -i  || true
echo "$prog: shell terminated."

# Repack archive
read -p "$prog: Recreate archive $archv ? [Y/n] " recreate
case $recreate in
	y|Y|"")
	echo "$prog: recreating archive"
	$call_pack
	;;
esac

# Clean up
cd $base
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

