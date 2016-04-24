#!/bin/bash
. $(dirname "$0")/init.sh

# This test script tries to enter an existing .tar archive, changing the contents,
# re-packing it, and then checks if the original archive file has been updated accordingly.

ARCHIVE='test.tar'

cd_tmpdir

 > empty-file        ; chmod 0644 empty-file
 echo foo > foo-file ; chmod 0644 foo-file
 echo bar > bar-file ; chmod 0600 bar-file

 archive_files='./empty-file ./foo-file ./bar-file'
 tar -cf $ARCHIVE $archive_files
 rm -f $archive_files

prepare_subshell <<SH
 # We're now inside the unpacked archive.
 # Alter the archive:

 chmod 0640 empty-file  # changed access mode
 rm foo-file  # deleted file
 echo baz > bar-file  # changed file contents, but unchanged access mode
 echo zog > .zog-file  # new file
SH

assertCmd "$WALK -y $ARCHIVE"

# Unpack altered archive, verify changes:
tar -xf $ARCHIVE
CLEANUP_FILES="$archive_files ./.zog-file"

[ ! -f foo-file ] || fail "foo-file was deleted, but is still in the archive!"
[   -f .zog-file ] || fail ".zog-file was created, but is not in the archive!"
assertCmdEq    "cat bar-file"  "baz" "bar-file was changed, but is unchanged in the archive!"
assertCmdEq    "cat .zog-file" "zog" ".zog-file is now in the archive, but has wrong contents!"
assertFileMode "empty-file"    "640" "empty-file's access mode was changed, but is unchanged in the archive!"
assertFileMode "bar-file"      "600" "bar-file was overwritten, now its access mode changed in the archive!"

success

