#!/bin/bash
. $(dirname "$0")/init.sh

# This test script checks if the archive directory root will only be archived with the -A option.

ARCHIVE='test.tar'

cd_tmpdir

 chmod 0755 .
 echo aAaAa > testfile
 tar -cf $ARCHIVE testfile
 CLEANUP_FILES='testfile'
 rm -f testfile

prepare_subshell <<SH
 # We're now inside the unpacked archive (without -A option).
 assertFileMode "." "755" "Archive working directory has unexpected access mode!"
 assertCmd "chmod 0701 ."
 # Will walk include the (changed) root directory entry in the archive?
SH

assertCmd "$WALK -y $ARCHIVE"
assertCmdEq "tar -tf $ARCHIVE" "./testfile" "Re-packed archive contents mismatch!"

prepare_subshell <<SH2
 # We're now inside the unpacked archive (WITH -A option).
 assertFileMode "." "755" "Archive working directory has unexpected access mode!"
 assertCmd "chmod 0700 ."
 # Will walk include the (changed) root directory entry in the archive?
SH2

assertCmd "$WALK -y -A $ARCHIVE"
expectedContents="$(echo -e "./\n./testfile")"
assertCmdEq "tar -tf $ARCHIVE" "$expectedContents" "Re-packed archive contents mismatch when using -A option!"

assertFileMode "." "755"
tar -xf $ARCHIVE .
assertFileMode "." "700" "Unpacking an archive containing a root directory entry did not actually change the directory's access mode!"

success

