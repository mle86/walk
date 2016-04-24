#!/bin/bash
. $(dirname "$0")/init.sh

# This test script calls walk on an archive not in the current directory,
# to check if the directory changes work out.

ARCHIVE='test.tar'

cd_tmpdir

 echo foo > foo-file
 tar -cf $ARCHIVE foo-file
 rm -f foo-file

prepare_subshell <<SH
 # We're now inside the unpacked archive.
 # Check our location:

 assertCmdEq "pwd" "$DIR/$ARCHIVE" "Unexpected location!"
 [ -f foo-file ] || fail "The archived file is missing! Are we really in the correct directory?"
SH

# Change into a different directory:
elsewhere="$(mktemp -d)"
cd "$elsewhere"

assertCmd "$WALK -y $DIR/$ARCHIVE"

# Seems to have worked so far.
# Are we back in our custom tmpdir?
assertCmdEq "pwd" "$elsewhere" "After walk exited, our location changed unexpectedly!"

cd $DIR
rmdir -v "$elsewhere"

success

