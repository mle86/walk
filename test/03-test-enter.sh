#!/bin/bash
. $(dirname "$0")/init.sh

# This test script tries to enter an existing .tar archive, verifying the extracted file contents.
# It also checks if walk changed the archive contents after re-packing it (it shouldn't).

ARCHIVE='test.tar'

cd_tmpdir

 umask 0022
 echo bBbBb > b-file
 > empty-file
 chmod 0400 empty-file
 echo WrItAbLe > .writable-file
 chmod 0666 .writable-file
 echo "#!/bin/sh" >  executable-file
 echo "echo yo"   >> executable-file
 chmod 0755 executable-file

 archive_files='./b-file ./empty-file ./.writable-file ./executable-file'
 tar -cf $ARCHIVE $archive_files
 rm -f $archive_files

prepare_subshell <<SH
 # We're now inside the unpacked archive.
 # Test the file contents:

 [ -f empty-file      ] || fail "empty-file was not unpacked!"
 [ -f b-file          ] || fail "b-file was not unpacked!"
 [ -f .writable-file  ] || fail ".writable-file was not unpacked!"
 [ -f executable-file ] || fail "executable-file was not unpacked!"
 [ -x executable-file ] || fail "executable-file is not executable!"

 assertCmdEmpty "cat empty-file"                      "empty-file is not empty!"
 assertCmdEq    "cat b-file"                  "bBbBb" "b-file has incorrect contents!"
 assertCmdEq    "stat -c '%a' empty-file"     "400"   "empty-file was unpacked with wrong access mode!"
 assertCmdEq    "stat -c '%a' .writable-file" "666"   ".writable-file was unpacked with wrong access mode!"
 assertCmdEq    "./executable-file"           "yo"    "executable-file did not run correctly!"
SH

contents1="$(tar -tvf $ARCHIVE | tarsort)"

assertCmd "$WALK -y $ARCHIVE"

contents2="$(tar -tvf $ARCHIVE | tarsort)"

assertEq "$contents2" "$contents1" "walk changed the archive contents for no good reason!"

success

