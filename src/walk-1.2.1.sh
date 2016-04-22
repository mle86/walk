#!/bin/sh
#set -e

#  walk v1.2.1
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


prog="$(basename "$0")"
errprefix="$prog: "
msgprefix="$prog: "

create_empty=
pack_root=

EXIT_SYNTAX=1
EXIT_HELP=0
EXIT_NOTFOUND=5
EXIT_NOTAFILE=4
EXIT_EXISTS=2
EXIT_UNKNOWNTYPE=3

msg  () { echo "$msgprefix$@" ; }
err  () { echo "$errprefix$@" >&2 ; }
fail () {
	# fail [EXITSTATUS=1] MESSAGE
	local status=1
	if [ -n "$2" ]; then
		status="$1"
		shift
	fi
	err "$1"
	exit $status
}
ask () {
	# 1=prompt, 2=default
	local response=
	read -p "$1 " response
	[ -z "$response" ] && response="$2"  # use default, might be empty itself
	[ "$response" = "y" -o "$response" = "Y" -o "$response" = "yes" -o "$response" = "Yes" ]  # is "yes"-like?
}


# Check arguments
syntaxline="syntax: $prog [-c] [-A] ARCHIVE "
if [ "$1" = "-h" -o "$1" = "--help" ]; then
	echo "$syntaxline"
	echo ""
	echo "walk v1.2.1 will unpack an archive file into a new directory of the"
	echo "same name and spawn a new shell within that directory. After said"
	echo "shell terminates, walk will ask you whether you want to re-create"
	echo "the archive from that directory and whether you want to delete the"
	echo "temporary directory."
	echo "Empty archives can be created with the -c option."
	echo "If the working directory root (.) should be archived too (tar and cpio"
	echo "support this), use the -A option.  NB: Unpacking such archives may change"
	echo "your current directory's owner and mode!"
	echo ""
	echo "Recognized archive types:"
	echo " - tar, tar.gz, tar.bz2, tar.xz (requires tar with built-in compression support)"
	echo " - 7-zip (requires 7zr)"
	echo " - zip, jar (requires zip/unzip)"
	echo " - rar (requires rar)"
	echo " - cpio, ar"
	echo ""
	exit $EXIT_HELP
fi
if [ "$1" = "-c" ]; then
	create_empty=yes
	shift
fi
if [ "$1" = "-A" ]; then
	pack_root=yes
	shift
fi
if [ -z "$1" ]; then
	errprefix=
	fail $EXIT_SYNTAX "$syntaxline"
fi

archv="$(readlink -f "$1")"  # absolute path
temp="$(dirname "$archv")/.$(basename "$archv")-WALK-$(date +'%Y%m%d-%H%M%S')"

if [ ! -e "$archv" -a -z "$create_empty" ]; then
	err "$archv not found"
	err "Do you want to create an empty archive? Use the -c option"
	exit $EXIT_NOTFOUND
fi
if [ -e "$archv" -a ! -f "$archv" ]; then
	fail $EXIT_NOTAFILE "$archv is not a file"
fi
if [ -e "$temp" ]; then
	fail $EXIT_EXISTS "File or folder $temp already exists!"
fi

usearchv="$temp"

#####################################################################

unpack_archive () {
	# Rename archive file
	mv "$archv" "$temp"

	# Unpack archive into new working dir of same name
	create_working_dir "$archv"
	fn_unpack "$usearchv"
}

create_working_dir () {
	# Don't set any special modes -- it'll depend on the user's umask.
	# If the unpacked archive contains a '.' entry, that will overwrite the mode anyway. 
	mkdir "$1"
	cd "$1"
}

enter_tempdir () {
	# Start new subshell:
	msg "starting new shell"
	${SHELL:-'/bin/bash'} -i  || true
	msg "shell terminated."
}

repack_archive () {
	if ask "Recreate archive $archv ? [Y/n]" y; then
		msg "recreating archive"
		if [ "$pack_root" ]; then
			fn_packroot "$usearchv"
		else
			fn_pack "$usearchv"
		fi
	fi
}

cleanup () {
	if ask "Delete temporary directory? [Y/n]" y; then
		msg "deleting temp dir"
		rm -rf "$archv"
	else
		save="${archv}-$(date +'%Y%m%d-%H%M')"
		msg "renaming temp dir to $save"
		mv "$archv" "$save"
	fi
	mv "$temp" "$archv"
}

tartype () {
	case "$1" in
		*"(gz"*" compressed"*|"X-"*".tgz"|"X-"*".tar.gz")
			# gzip
			taropt="$taropt_gzip $taropt"
			;;
		*"(bz"*"2 compressed"*|"X-"*".tar.bz2"|"X-"*".tbz2"|"X-"*".tar.bz"|"X-"*".tbz")
			# bz2
			taropt="$taropt_bzip2 $taropt"
			;;
		*"(xz"*" compressed"*|"X-"*".tar.xz"|"X-"*".txz")
			# xz
			taropt="$taropt_xz $taropt"
			;;
		*"gnu"*") ("*|*"compr"*|*"extract"*)
			# unknown
			err "UNKNOWN TAR TYPE"
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
		fail $EXIT_UNKNOWNTYPE "unknown archive file type!"
	fi
}

# find_root() finds all files and directories below the currect directory, including the directory itself.
# find_all() finds all files and directories below the currect directory, excluding the start directory's "." entry.
# find_flat() finds all files and directories immediately below the current directory (no recursion), excluding the start directory's "." entry.
find_root () { find . "$@" -print0 ; }
find_all  () { find_root -mindepth 1 "$@" ; }
find_flat () { find_all -maxdepth 1 "$@" ; }

archvtype () {
	local filetype=
	if [ -e "$archv" ]; then
		# File exists, try to determine type using 'file' tool
		filetype="$(file -Nbz "$archv" 2>/dev/null | tr '[A-Z]' '[a-z]')" || return 1
	else
		# File does not yet exist -- try to guess type from filename itself
		filetype="X-${archv}"
	fi

	case "$filetype" in
		*"tar archive"*|"X-"*".tar"|"X-"*".tar."*|"X-"*".tgz"|"X-"*".tbz2"|"X-"*".tbz"|"X-"*".txz")
			taropt="-pvS"
			local taropt_extract='-s'
			local taropt_gzip='-z'
			local taropt_bzip2='-j'
			local taropt_xz='-J'
			tartype "$filetype" || return 2
			fn_unpack   () {             tar -x $taropt $taropt_extract -f "$1"             ; }
			fn_packroot () {             tar -c $taropt                 -f "$1" .           ; }
			fn_pack     () { find_flat | tar -c $taropt                 -f "$1" --null -T - ; }
			;;
		"7-zip archive"*|"X-"*".7z")
			z7opt="-bd -ms=on"
			fn_unpack   () { 7zr e $z7opt "$1"   ; }
			fn_packroot () { 7zr a $z7opt "$1" . ; }
			fn_pack     () { 7zr a $z7opt "$1" . ; }
			;;
		*"rar archive"*|"X-"*".rar")
			raropt="-o+ -ol -ow -r -r0 -tl"
			fn_unpack   () { rar e $raropt "$1"   ; }
			fn_packroot () { rar u $raropt "$1" . ; }
			fn_pack     () { rar u $raropt "$1" . ; }
			;;
		*"zip archive"*|*"Jar file data (zip)"*|"X-"*".zip"|"X-"*".jar")
			export UNZIP=
			export ZIP=
			export ZIPOPT=
			zipopt="-v"
			fn_unpack   () { unzip -o -X    $zipopt "$1"   ; }
			fn_packroot () { zip   -u -y -r $zipopt "$1" . ; }
			fn_pack     () { zip   -u -y -r $zipopt "$1" . ; }
			;;
		*"cpio archive"*|"X-"*".cpio")
			cpioopt="-v -B -F"
			fn_unpack   () { cpio -i -d --no-absolute-filenames --sparse $cpioopt "$1" ; }
			fn_packroot () { find_root | cpio -0 -o -H crc               $cpioopt "$1" ; }
			fn_pack     () { find_all  | cpio -0 -o -H crc               $cpioopt "$1" ; }
			;;
		*" ar archive"*|"X-"*".a")
			aropt="sv"
			fn_unpack   () {                              ar x${aropt} "$1" ; }
			fn_packroot () { find_all -type f | xargs -0r ar r${aropt} "$1" ; }
			fn_pack     () { find_all -type f | xargs -0r ar r${aropt} "$1" ; }
			;;
		*)
			return 1
			;;
	esac
	return 0
}

#####################################################################

determine_archive_type

if [ -e "$archv" ]; then
	msg "unpacking archive"
	unpack_archive
else
	msg "creating archive"
	create_working_dir "$archv"
fi

enter_tempdir

repack_archive
cleanup

# fin
exit 0

