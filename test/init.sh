#!/bin/sh
set -e  # fail on errors

THIS="$(readlink -f "$0")"
TESTNAME="$(basename --suffix='.sh' "$THIS")"
HERE="$(dirname "$THIS")"
WALK="$(readlink -f "$HERE/../src/walk-1.2.1.sh")"

export ASSERTSH="$HERE/assert.sh"  # The assertion functions script. The subshell might need them itself.
export ERRCOND="$HERE/errcond-$TESTNAME"  # Flag file. Should not exist yet. Can be created by a subshell script to signal an error.
export SHELL="true"  # Don't run a real subshell by default. Can be changed via prepare_subshell().

DIR=  # Current temporary working directory. Should be deleted by cleanup() later.
TMPSH=  # The subshell to run inside 'walk' instead of bash.
ARCHIVE=  # The archive filename which was created/entered.
IN_SUBSHELL=  # Will be set to 'yes' for subshells by prepare_subshell().
CLEANUP_FILES=  # Additional files and empty directories to delete. Separate with spaces. Be careful, they'll be deleted with "rm -fd".
STDFILES=  # Files and top directories prepared for the standard archive.
RMSTDFILES=  # All files and directories prepared for the standard archive. Suitable for "rm -fd".

# Code duplication: this block of constants is copied from walk.sh.
EXIT_SYNTAX=1
EXIT_HELP=0
EXIT_NOTFOUND=5
EXIT_NOTAFILE=4
EXIT_EXISTS=2
EXIT_UNKNOWNTYPE=3

rm -f "$ERRCOND"  # this may have been left over from an earlier, broken test 

# Load assertion and error functions.
# This must be done prior to our cleanup() definition, or it will be overwritten.
. $ASSERTSH

echo "${color_info}Starting ${TESTNAME}...${color_normal}"

cd_tmpdir () {
	# Creates a temporary directory to work in.
	# Also changes $ERRCOND to point into the new directory,
	# so we don't clutter the test root with them.
	DIR="$(mktemp -d)"
	export ERRCOND="$DIR/errcond-$TESTNAME"
	cd "$DIR"
}

prepare_subshell () {
	[ -n "$TMPSH" ] && rm -v "$TMPSH"  # delete earlier subshell file (in case of multiple calls)
	TMPSH="$(mktemp --tmpdir="$DIR" 'tmp.subshell.XXXXXX.sh')"
	echo "#!/bin/sh" > $TMPSH
	echo "export IN_SUBSHELL=yes" >> $TMPSH
	echo ". \$ASSERTSH" >> $TMPSH
	cat >> $TMPSH
	chmod +x $TMPSH
	export SHELL="$TMPSH"
}

success () {
	echo "${color_success}Success: ${TESTNAME}${color_normal}"
	cleanup
	exit 0
}

cleanup () {
	[ -n "$TMPSH"   -a -f "$TMPSH"   ] && rm --one-file-system -v "$TMPSH"
	[ -n "$ARCHIVE" -a -f "$ARCHIVE" ] && rm --one-file-system -v "$(readlink -f "$ARCHIVE")"
	[ -n "$ERRCOND" -a -f "$ERRCOND" ] && rm --one-file-system -v "$ERRCOND"
	[ -n "$CLEANUP_FILES"            ] && rm --one-file-system -vfd $CLEANUP_FILES
	[ -n "$DIR"     -a -d "$DIR"     ] && rm --one-file-system -vd "$DIR"
}

tarsort () {
	# Sorts the input (tar -tv) by filenames.
	# Expected format:
	#  -rw-r--r-- mle/mle           0 2016-04-24 22:17 ./filename
	sort -k 6
}

prepare_standard_archive () {
	local old_umask=$(umask)

	> empty-file
	umask 0022
	echo HIDDEN     > .hidden-file
	echo TEST       > test-file
	echo PROTECTED  > protected-file  ; chmod 0600 protected-file
	echo EXECUTABLE > executable-file ; chmod 0755 executable-file
	mkdir -p subdir/emptysubdir/
	echo SUBFILE > subdir/subfile

	umask $old_umask
	STDFILES='./empty-file ./test-file ./.hidden-file ./protected-file ./executable-file ./subdir/'
	RMSTDFILES="./subdir/subfile ./subdir/emptysubdir/ ./subdir/subfile2 $STDFILES"
	CLEANUP_FILES="$CLEANUP_FILES $RMSTDFILES"
}

delete_standard_archive_files () {
	rm -fd $RMSTDFILES
}

