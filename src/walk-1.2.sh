#!/bin/sh
#set -e
set -x

#  walk v1.2
#  
#  Copyright (C) 2015  Maximilian L. Eul
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


prog=`basename "$0"`
create_empty=

# Check arguments
if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "syntax: $prog [-c] ARCHIVE "
	echo ""
	echo "walk v1.2 will unpack an archive file into a new directory of the"
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
if [ "$1" = "-c" ]; then
	create_empty=1
	shift
fi
if [ -z "$1" ]; then
	echo "syntax: $prog [-c] ARCHIVE ">&2
	exit 1
fi

archv="$(readlink -f "$1")"  # absolute path
temp="$(dirname "$archv")/.$(basename "$archv")-WALK-"`date '+%Y%m%d-%H%M%S'`

if [ ! -e "$archv" -a -z "$create_empty" ]; then
	echo "$prog: $archv not found" >&2
	exit 5
fi
if [ -e "$archv" -a ! -f "$archv" ]; then
	echo "$prog: $archv is not a file" >&2
	exit 4
fi
if [ -e "$temp" ]; then
	echo "$prog: File or folder $temp already exists!" >&2
	exit 2
fi

usearchv="$temp"
call_pack=
call_unpack=
suffix_pack="."
suffix_unpack=

#####################################################################

unpack_archive () {
	# Determine archive file type

	#echo "  PACK: $call_pack"
	#echo "UNPACK: $call_unpack"
	#exit

	# Rename archive file
	mv "$archv" "$temp"

	# Unpack archive
	echo "$prog: unpacking archive"
	mkdir -m 0700 "$archv"
	cd "$archv"
	$call_unpack "$usearchv" $suffix_unpack
}

create_archive () {
	echo "$prog: creating archive"
	mkdir -m 0755 "$archv"
	cd "$archv"
}

enter_tempdir () {
	# Start walking shell
	echo "$prog: starting new shell"
	unset IGNOREEOF
	${SHELL:-'/bin/bash'} -i  || true
	echo "$prog: shell terminated."
}

repack_archive () {
	read -p "$prog: Recreate archive $archv ? [Y/n] " recreate
	case "$recreate" in
		y|Y|yes|"")
		echo "$prog: recreating archive"
		sh -c "$call_pack \"$usearchv\" $suffix_pack"
		;;
	esac
}

cleanup () {
	read -p "$prog: Delete temporary directory? [Y/n] " deltemp
	case "$deltemp" in
		y|Y|yes|"")
			echo "$prog: deleting temp dir"
			rm -rf "$archv"
			;;
		*)
			save="${archv}-`date +'%Y%m%d-%H%M'`"
			echo "$prog: renaming temp dir to $save"
			mv "$archv" "$save"
			;;
	esac
	mv "$temp" "$archv"
}

tartype () {
	echo "[TARTYPE:$1]"
	case "$1" in
		*"(gz"*" compressed"*|"X-"*".tgz"|"X-"*".tar.gz")
			# gzip
			taropt="$taropt_gzip $taropt"
			;;
		*"(bz"*"2 compressed"*|"X-"*".tar.bz2"|"X-"*".tbz2"|"X-"*".tar.bz"|"X-"*".tbz")
			# bz2
			taropt="$taropt_bzip2 $taropt"
			;;
		*"(XZ"*" compressed"*|"X-"*".tar.xz"|"X-"*".txz")
			# xz
			taropt="$taropt_xz $taropt"
			;;
		*"GNU"*") ("*|*"compr"*|*"extract"*)
			# unknown
			echo UNKN TAR
			return 1
			;;
		*)
			# plain tar
			;;
	esac
	return 0
}

determine_archive_type () {
	if ! archvtype; then
		echo "$prog: unknown archive file type!" >&2
		exit 3
	fi
}

archvtype () {
	if [ -e "$archv" ]; then
		ft=`file -Nbz "$archv" 2>/dev/null | tr \'[A-Z]\' \'[a-z]\'` || return 1
	else
		ft="X-${archv}"
	fi

	echo "[FT=$ft]"

	case "$ft" in
		*"tar archive"*|"X-"*".tar"|"X-"*".tar."*|"X-"*".tgz"|"X-"*".tbz2"|"X-"*".tbz"|"X-"*".txz"****)
			taropt="--same-owner -spvSf"
			taropt_gzip='-z'
			taropt_bzip2='-j'
			taropt_xz='-J'
			tartype "$ft" || return 2
			call_unpack="tar -x $taropt"
			call_pack="tar -c $taropt"
			;;
		"7-zip archive"*|"X-"*".7z")
			z7opt="-bd -ms=on"
			call_unpack="7zr e $z7opt"
			call_pack="7zr a $z7opt"
			;;
		*"rar archive"*|"X-"*".rar")
			raropt="-o+ -ol -ow -r -r0 -tl"
			call_unpack="rar e $raropt"
			call_pack="rar u $raropt"
			;;
		*"zip archive"*|"X-"*".zip")
			zipopt="-v"
			call_unpack="UNZIP= unzip -o -X $zipopt"
			call_pack="ZIP= ZIPOPT= zip -u -y -R $zipopt"
			;;
		*"cpio archive"*|"X-"*".cpio")
			cpioopt="-v -B -F"
			call_unpack="cpio -i -d --no-absolute-filenames --sparse $cpioopt"
			call_pack="find . -print0 -mindepth 1 | cpio -0 -o -H crc $cpioopt"
			suffix_pack=
			;;
		*" ar archive"*|"X-"*".a")
			aropt="sv"
			call_unpack="ar x${aropt}"
			call_pack="find . -mindepth 1 ; find . -mindepth 1 | xargs ar r${aropt}"
			suffix_pack=
			;;
		*)
			return 1
			;;
	esac
	return 0
}

#####################################################################

determine_archive_type

echo "1: U($usearchv) A($archv) T($temp)"
if [ -e "$archv" ]; then
	unpack_archive
else
	create_archive
fi

echo "2: U($usearchv) A($archv) T($temp)"

enter_tempdir

repack_archive
echo "3: U($usearchv) A($archv) T($temp)"
cleanup

# fin
exit 0

