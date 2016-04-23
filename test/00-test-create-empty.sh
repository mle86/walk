#!/bin/bash
. $(dirname "$0")/init.sh

# This test script tries to create a new, empty .tgz archive.

ARCHIVE='test.tar.gz'

cd_tmpdir
prepare_subshell <<SH
 # We're now inside an empty archive directory.
 assertCmdEq    "pwd"      "$DIR/$ARCHIVE" "Unexpected current directory!"
 assertCmdEmpty "ls -1A ."                 "Current directory is not empty!"
SH

assertCmd "$WALK -c -y $ARCHIVE"

# The subshell has been left, there should now be a new, empty archive
[ -e $ARCHIVE ] || fail "No archive file has been created!"
[ -f $ARCHIVE ] || fail "Archive filename exists, but is not a file!"
assertCmdEmpty "tar -tzf $ARCHIVE" "Archive was created, but is not empty!"

success

