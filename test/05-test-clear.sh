#!/bin/bash
. $(dirname "$0")/init.sh

# This test script tries to enter an existing .tar archive, removing all contents,
# re-packing it, and then checks if the archive is now actually empty.

ARCHIVE='test.tar'

cd_tmpdir

 > empty-file
 echo hidden > .hidden-file
 echo foo > foo-file

 archive_files='./empty-file ./foo-file ./.hidden-file'
 tar -cf $ARCHIVE $archive_files
 rm -f $archive_files

prepare_subshell <<SH
 # We're now inside the unpacked archive.
 # Clear it out:

 assertCmd "rm empty-file"
 assertCmd "rm foo-file"
 assertCmd "rm .hidden-file"
SH

assertCmd "$WALK -y $ARCHIVE"

[ -f "$ARCHIVE" ] || fail "walk did not re-create an empty archive, but deleted it!"

assertCmdEmpty "tar -tvf $ARCHIVE" "walk re-created an empty archive, but it's not actually empty!"

success

