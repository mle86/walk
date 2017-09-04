#!/bin/sh

umask 0022

WALK="$(readlink -f -- "$HERE/../src/walk.sh")"

# Code duplication: this block of constants is copied from walk.sh.
EXIT_SYNTAX=1
EXIT_HELP=0
EXIT_NOTFOUND=5
EXIT_NOTAFILE=4
EXIT_EXISTS=2
EXIT_UNKNOWNTYPE=3
EXIT_PACKFAIL=6
EXIT_UNPACKFAIL=7
EXIT_NOPROG=127


ARCHIVE=

hook_cleanup () {
	[ -n "$ARCHIVE" -a -f "$ARCHIVE" ] && rm -v -- "$ARCHIVE"
	:;
}

STDFILES=  # Files and top directories prepared for the standard archive.
RMSTDFILES=  # All files and directories prepared for the standard archive. Suitable for "rm -fd".

prepare_standard_archive () {
	> empty-file
	echo HIDDEN     > .hidden-file
	echo TEST       > test-file
	echo PROTECTED  > protected-file  ; chmod 0600 protected-file
	echo EXECUTABLE > executable-file ; chmod 0755 executable-file
	mkdir -p subdir/emptysubdir/
	echo SUBFILE > subdir/subfile

	STDFILES='./empty-file ./test-file ./.hidden-file ./protected-file ./executable-file ./subdir/'
	RMSTDFILES="./subdir/subfile ./subdir/emptysubdir/ ./subdir/subfile2 $STDFILES"
	CLEANUP_FILES="$CLEANUP_FILES $RMSTDFILES"
}

delete_standard_archive_files () {
	rm -fd -- $RMSTDFILES
}

verify_standard_archive () {
	# see prepare_standard_archive() in init.sh

	[ -e test-file       ] || fail "test-file is missing!"
	[ -e empty-file      ] || fail "empty-file is missing!"
	[ -e protected-file  ] || fail "protected-file is missing!"
	[ -e executable-file ] || fail "executable-file is missing!"
	[ -e .hidden-file    ] || fail ".hidden-file is missing!"

	[ ! -s empty-file      ] || fail "empty-file is not empty!"
	[   -x executable-file ] || fail "executable-file is not executable!"

	assertFileMode 'protected-file' 600
	assertFileMode 'subdir/subfile' 644

	assertCmdEq 'cat .hidden-file' 'HIDDEN' "hidden-file has wrong content!"
	assertCmdEq 'cat subdir/subfile' 'SUBFILE' "subdir/subfile has wrong content!"
	assertCmdEq 'cat protected-file' 'PROTECTED' "protected-file has wrong content!"
}

verify_modified_standard_archive () {
	[ ! -e test-file     ] || fail "test-file was deleted, but is still in the archive!"
	[ -e empty-file      ] || fail "empty-file is missing!"
	[ -e protected-file  ] || fail "protected-file is missing!"
	[ -e executable-file ] || fail "executable-file is missing!"
	[ -e .hidden-file    ] || fail ".hidden-file is missing!"

	[ ! -s empty-file      ] || fail "empty-file is no longer empty!"
	[   -x executable-file ] || fail "executable-file is not executable!"
	[   -x .hidden-file    ] || fail ".hidden-file should now be executable, but still isn't!"

	assertFileMode 'protected-file' 600
	assertFileMode 'subdir/subfile' 644

	assertCmdEq 'cat .hidden-file' 'HIDDEN' "hidden-file has wrong content!"
	assertCmdEq 'cat subdir/subfile' 'SUBFILE' "subdir/subfile has wrong content!"
	assertCmdEq 'cat protected-file' 'PROT2' "protected-file has wrong content!"
	assertCmdEq 'cat subdir/subfile2' 'SUB2' "added file subdir/subfile2 has wrong content!"
}

modify_standard_archive () {
	echo PROT2 > protected-file  # changed content
	echo SUB2 > subdir/subfile2  # new file
	rm test-file  # deleted file
	chmod 0755 .hidden-file  # changed access mode
}

restore_flattened_standard_archive () {
	# Some archive types don't do subdirectores (e.g. GNU ar).
	# They will archive all files found within the archive directory,
	# they will simply flatten the structure.
	
	# Restore the original directory structure to see what happens
	# and to have verify_..._standard_archive() work as expected:
	assertCmd "mkdir subdir/ && mkdir subdir/emptysubdir/"
	assertCmd "mv subfile subdir/"
	mv subfile2 subdir/ 2>/dev/null || true
}

tarsort () {
	# Sorts the input (tar -tv) by filenames.
	# Expected format:
	#  -rw-r--r-- mle/mle           0 2016-04-24 22:17 ./filename
	sort -k 6
}

