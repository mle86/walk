#!/bin/sh
set -e

#  walk v2.2.1
#  
#  Copyright (C) 2017-2020  Maximilian L. Eul
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


prog="$(basename -- "$0")"
errprefix="$prog: "
msgprefix="$prog: "

create_empty=
pack_root=
force_answer=
quiet=

reentry=
archv=
temp=
usearchv=
type_found=

EXIT_SYNTAX=1
EXIT_HELP=0
EXIT_NOTFOUND=5
EXIT_NOTAFILE=4
EXIT_EXISTS=2
EXIT_UNKNOWNTYPE=3
EXIT_PACKFAIL=6
EXIT_UNPACKFAIL=7
EXIT_NOPROG=127

msg     () { printf '%s\n' "$msgprefix$*" ; }
err     () { printf '%s\n' "$errprefix$*" >&2 ; }
verbose () { [ "$quiet" ] || msg "$*" ; }

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
	# ask PROMPT [DEFAULT]
	local response=
	if [ "$force_answer" = "default" ]; then
		# use default answer for all questions,
		# or 'yes' if there is no default for this question
		response="${2:-yes}"
	elif [ "$force_answer" ]; then
		# use $force_answer for all questions
		response="$force_answer"
	else
		# show prompt, query answer from user
		read -p "$1 " response
		[ -z "$response" ] && response="$2"  # use default, might be empty itself
	fi
	[ "$response" = "y" -o "$response" = "Y" -o "$response" = "yes" -o "$response" = "Yes" ]  # is "yes"-like?
}

expect () {
	# expect STATUS_LIST COMMAND...
	#  Will execute COMMAND.
	#  If the exit status is within the STATUS_LIST, success (0) is returned.
	#  If the exit status is NOT within the STATUS_LIST, a failure status is returned (either the original status or 1, whichever is greater).
	#  STATUS_LIST should be a space-separated list of allowed exit status values.
	#  Example:  expect "0 1" unzip -X archive.zip
	#            This will return success if the unzip command returned either 0 or 1,
	#            but return any other failure status unchanged.
	local status_list="$1" ; shift

	local status=0
	( "$@" ) || status=$?

	case " $status_list " in
		*" $status "*)
			# ok, it's an allowed status
			return 0
			;;
		*)
			# failure
			[ "$status" -eq 0 ] && return 1
			return $status
	esac
}

syntaxline="syntax: $prog [-cyAq] ARCHIVE "
help () {
	printf '%s\n' "$syntaxline"
	echo ""
	echo "walk v2.2.1 will unpack an archive file into a new directory of the"
	echo "same name and spawn a new shell within that directory. After said"
	echo "shell terminates, walk will ask you whether you want to re-create"
	echo "the archive from that directory and whether you want to delete the"
	echo "temporary directory."
	echo "Empty archives can be created with the -c option."
	echo "The -y option causes all questions to be answered with \`yes'."
	echo "If the working directory root (.) should be archived too (tar and cpio"
	echo "support this), use the -A option.  NB: Unpacking such archives may change"
	echo "your current directory's owner and mode!"
	echo ""
	echo "Recognized archive types:"
	echo " - tar, tar.gz, tar.bz2, tar.xz (requires tar with built-in compression support)"
	echo " - 7-zip (requires 7z/7za/7zr)"
	echo " - zip, jar (requires zip/unzip)"
	echo " - rar (requires rar)"
	echo " - cpio, ar"
	echo ""
	exit ${1:-$EXIT_HELP}
}

read_arguments () {
	for arg in "$@"; do
		# find the '--help' long option, but not after '--'
		[ "$arg" = "--help" ] && help
		[ "$arg" = "--"     ] && break
	done

	while getopts 'cyAqh' opt; do case "$opt" in
		c)	create_empty=yes ;;
		y)	force_answer=yes ;;
		A)	pack_root=yes ;;
		q)	quiet=yes ;;
		h)	help ;;
		--)	;;
		*)	exit $EXIT_SYNTAX ;;
	esac ; done
	shift "$(($OPTIND - 1))"

	if [ -z "$1" ]; then
		# missing filename argument
		errprefix=
		fail $EXIT_SYNTAX "$syntaxline"
	fi
	[ -z "$2" ] || fail $EXIT_SYNTAX "more than one filename given"

	archv="$1"
}

unpack_archive () {
	# Rename archive file
	mv -- "$archv" "$temp"

	# Unpack archive into new working dir of same name
	create_working_dir "$archv" "$temp"

	# Extract archive there
	cd -- "$archv"
	local status=0
	fn_unpack "$usearchv" || status=$?

	if [ "$status" -ne 0 ]; then
		# Restore archive file, remove empty working directory
		err "Unpacking failed (status $status)."
		cd -- "$(dirname -- "$archv")"
		rm -rf -- "$archv"
		mv -- "$temp" "$archv"
		exit $EXIT_UNPACKFAIL
	fi
}

# create_working_dir NEWDIRNAME [ORIGINALARCHIVENAME]
create_working_dir () {
	local modeopt=
	if [ -n "$2" ]; then
		# Directory mode should be similar to archive file's mode, plus +x because it's a directory.
		# NB: If the unpacked archive contains a '.' entry, that will overwrite the mode!
		modeopt="--mode=$(calculate_dirmode "$(stat -c '%#a' -- "$2")")"
	else
		: # Don't set any special modes -- it'll depend on the user's umask.
	fi

	mkdir $modeopt -- "$1"
}

enter_tempdir () {
	# Start new subshell:
	cd -- "$archv/"  # unpack_archive() already does this for unpacking, but $archv is an absolute path
	verbose "starting new shell"
	${SHELL:-'/bin/bash'} -i  || true
	verbose "shell terminated."
}

fn_delete () {
	# Default function.
	# Many archiver programs won't completely overwrite existing archives,
	# but will instead try to update them, often incorrectly.
	# In this case, it's better to simply delete and completely re-create the archive.
	# Overwrite this function with an empty dummy function
	# for archivers which will happily overwrite existing archives (like tar)
	# or which can update existing archives correctly.

	if [ -f "$1" ]; then
		rm -- "$1"
	elif [ -n "$create_empty" ]; then
		: # Ok, there is no original archive file, but that's because we're just now creating it.
	else
		fail "could not remove original archive '$1': file not found"
	fi
}

fn_packroot () {
	# Default function.
	# Only a few archivers can actually include the archive's root directory (tar and cpio can, for example).
	# This behavior is triggered with the -A option.
	# For archivers which cannot do it,
	# well just fall-back to the regular pack function:
	fn_pack "$@"
}

repack_archive () {
	if ask "Recreate archive $archv ? [Y/n]" y; then
		msg "recreating archive"
		fn_delete "$usearchv"
		local status=0
		if [ "$pack_root" ]; then
			fn_packroot "$usearchv" || status=$?
		else
			fn_pack "$usearchv" || status=$?
		fi

		if [ "$status" -ne 0 ]; then
			rm -f "$usearchv"
			err "Repacking failed (status $status)."
			err "Working directory kept: $archv"
			exit $EXIT_PACKFAIL
		fi
	fi
}

cleanup () {
	if ask "Delete temporary directory? [Y/n]" y; then
		verbose "deleting temp dir"
		rm -rf -- "$archv"
	else
		local save="${archv}-$(date +'%Y%m%d-%H%M')"
		msg "renaming temp dir to $save"
		mv -- "$archv" "$save"
	fi

	if [ -f "$temp" ]; then
		# restore original archive
		mv -- "$temp" "$archv"
	elif [ "$create_empty" ]; then
		: # This is okay. It happens if the user walked into a new archive (-c), but chose to not create it at the end.
	else
		err "Original archive file '$temp' not found!"
	fi
}

quiet_stdout () {
	if [ "$quiet" ]; then
		"$@" >/dev/null
	else
		"$@"
	fi
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
	if ! archvtype "$1"; then
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
	[ "$type_found" ] && return 0  # only check once

	local filetype=
	if [ -f "$1" ]; then
		# File exists, try to determine type using 'file' tool
		filetype="$(file -Nbz -- "$1" 2>/dev/null | tr '[A-Z]' '[a-z]')" || return 1
	else
		# File does not yet exist -- try to guess type from filename itself
		filetype="X-$1"
	fi

	case "$filetype" in
		*"tar archive"*|"X-"*".tar"|"X-"*".tar."*|"X-"*".tgz"|"X-"*".tbz2"|"X-"*".tbz"|"X-"*".txz")
			taropt="-pS"
			[ "$quiet" ] || taropt="${taropt}v"
			local taropt_gzip='-z'
			local taropt_bzip2='-j'
			local taropt_xz='-J'
			tartype "$filetype" || return 2
			fn_delete   () { :; }  # not necessary, tar will overwrite the archive
			fn_unpack   () {             tar -x $taropt -s              -f "$1"             ; }
			fn_packroot () {             tar -c $taropt                 -f "$1" .           ; }
			fn_pack     () { find_flat | tar -c $taropt                 -f "$1" --null -T - ; }
			;;
		"7-zip archive"*|"X-"*".7z")
			z7opt="-bd -ms=on"
			fn_unpack   () { quiet_stdout _7z x $z7opt "$1"   ; }
			fn_pack     () { quiet_stdout _7z a $z7opt "$1" . ; }
			;;
		*"rar archive"*|"X-"*".rar")
			raropt="-o+ -ol -ow -r0 -tl"
			fn_unpack   () { quiet_stdout rar x $raropt "$1"   ; }
			fn_pack     () { quiet_stdout rar a $raropt "$1" . ; }
			;;
		*"zip archive"*|*"jar file data (zip)"*|*"java archive data (jar)"*|"X-"*".zip"|"X-"*".jar")
			export UNZIP=
			export ZIP=
			export ZIPOPT=
			zipopt=""
			[ "$quiet" ] && zipopt="$zipopt -q"
			fn_unpack   () { expect "0 1" unzip -X    $zipopt "$1"   ; }
			fn_pack     () {              zip   -y -r $zipopt "$1" . ; }
			# Updating archives with the --filesync mode would be faster,
			# but Info-ZIP v3.0 does not consider changed file access modes update-worthy.
			;;
		*"cpio archive"*|"X-"*".cpio")
			cpioopt="-B"
			[ "$quiet" ] && cpioopt="$cpioopt --quiet"
			[ "$quiet" ] || cpioopt="$cpioopt -v"
			fn_delete   () { :; }  # not necessary, cpio will overwrite the archive
			fn_unpack   () { cpio -i -d --no-absolute-filenames --sparse $cpioopt -F "$1" ; }
			fn_packroot () { find_root | cpio -0 -o -H crc               $cpioopt -F "$1" ; }
			fn_pack     () { find_all  | cpio -0 -o -H crc               $cpioopt -F "$1" ; }
			;;
		*" ar archive"*|"X-"*".a"|"X-"*".ar")
			aropt="oPU"
			[ "$quiet" ] || aropt="${aropt}v"
			fn_unpack   () {                              ar  x${aropt} "$1" ; }
			fn_pack     () { find_all -type f | xargs -0r ar rs${aropt} "$1" ; }
			;;
		*)
			return 1
			;;
	esac
	type_found=yes
	return 0
}

test_reentry () {
	# Test if $archv is a directory that can be re-entered,
	# and set $temp/$reentry if so.
	# This is the case if there is still a temporary archive of the same name around.
	# and/or the directory has an archive filename extension.
	[ -d "$archv/" ] || return 1

	archv="$(readlink -f -- "$archv")"
	local pattern=".$(basename -- "$archv")-WALK-????????-??????"

	if temp="$(find -maxdepth 1 -type f -name "$pattern" -print -quit)" && [ -n "$temp" ]; then
		# Okay, found the original archive!
		msg "found earlier archive file '$temp'"
		reentry=yes
		temp="$(readlink -f -- "$temp")"  # get absolute filename

		return 0
	fi

	# No renamed original archive found.
	# Maybe the user just wants to create a fresh archive out of a directory,
	# or this is actually a re-entry into a failed "walk -c" directory
	# (which leaves no renamed archive behind).
	# Is the directory filename enough for a filetype match?
	if archvtype "$archv"; then
		# Okay, the directory name corresponds to a known archive type!
		reentry=yes
		temp=

		return 0
	fi

	# There is no renamed original archive,
	# and the target directory name does not look like an archive either.
	# Give up:
	false
}

# calculate_dirmode OCTALFILEMODE
#  Finds a suitable mode for a directory based on a file's octal mode string (e.g. "755")
#  Having read access to the file grants read and execute access to the directory;
#  having write access to the file grants write access to the directory.
#  Output is a chmod mode strings like "u=rwx,g=rx,o=".
#  The owner always gets rwx or the unpacking might fail.
calculate_dirmode () {
	local mode="0$1"  # add "0" prefix to make sure $(()) reads this as an octal number
	local setmode_g=
	local setmode_o=
	[ "$(($mode & 0060))" -gt 0 ] && setmode_g="${setmode_g}rx"
	[ "$(($mode & 0020))" -gt 0 ] && setmode_g="${setmode_g}w"
	[ "$(($mode & 0006))" -gt 0 ] && setmode_o="${setmode_o}rx"
	[ "$(($mode & 0002))" -gt 0 ] && setmode_o="${setmode_o}w"

	printf '%s\n' "u=rwx,g=${setmode_g},o=${setmode_o}"
}

# findbin BINARY...
#  Returns the path of the first BINARY that which(1) could find.
findbin () {
	local list="$*"
	while [ $# -gt 0 ]; do
		which "$1" && return
		shift
	done
	fail $EXIT_NOPROG "binary not found: $list"
}

_7z () {
	local bin=
	bin=$(findbin 7z 7za 7zr) || exit $?
	"$bin" "$@"
}

abspath () { readlink -f -- "$1" ; }

# tempname ARCHIVE
#  Prints a suitable temporary filename for the ARCHIVE.
#  This assumes that ARCHIVE is an absolute path.
tempname () { printf '%s\n' "$(dirname -- "$1")/.$(basename -- "$1")-WALK-$(date +'%Y%m%d-%H%M%S')" ; }


#####################################################################


read_arguments "$@"

if [ ! -e "$archv" ] && [ -z "$create_empty" ]; then
	err "$archv not found"
	err "Do you want to create an empty archive? Use the -c option"
	exit $EXIT_NOTFOUND
fi

if [ -e "$archv" ] && [ ! -f "$archv" ]; then
	if [ ! -d "$archv/" ] || ! test_reentry; then
		# it's not a re-enterable directory. give up:
		fail $EXIT_NOTAFILE "$archv is not a file"
	fi
fi

archv="$(abspath "$archv")"
[ -n "$temp" ] || temp="$(tempname "$archv")"

if [ -e "$temp" ] && [ -z "$reentry" ]; then
	fail $EXIT_EXISTS "File or folder $temp already exists!"
fi

usearchv="$temp"

#####################################################################

if [ "$reentry" ]; then
	msg "re-entering archive directory"
	determine_archive_type "${temp:-$archv}"
elif [ -f "$archv" ]; then
	verbose "unpacking archive"
	determine_archive_type "$archv"
	unpack_archive
else
	msg "creating archive"
	determine_archive_type "$archv"
	create_working_dir "$archv"
fi

enter_tempdir

repack_archive
cleanup

# fin
exit 0

