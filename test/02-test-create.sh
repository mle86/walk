#!/bin/bash
. $(dirname "$0")/init.sh

# This test script tries to create a new .tgz archive.

ARCHIVE='test.tgz'

cd_tmpdir
prepare_subshell <<SH
 umask 0022
 > empty-file
 echo AAaa > aaaa-file
 dd if=/dev/urandom of=random-file bs=1024 count=1
 chmod 0600 aaaa-file
SH

assertCmd "$WALK -c -y $ARCHIVE"

# The subshell has been left, there should now be a new archive
[ -e $ARCHIVE ] || fail "No archive file has been created!"
[ -f $ARCHIVE ] || fail "Archive filename exists, but is not a file!"

expectedList="$(echo -e "./aaaa-file\n./empty-file\n./random-file")"
assertCmdEq "tar -tzf $ARCHIVE | sort" "$expectedList" "Archive was created, but has wrong contents!"
CLEANUP_FILES='./aaaa-file ./empty-file ./random-file'
# Archive seems to contain the correct files, and only the correct files.

# Now verify the file contents:
tar -xzf $ARCHIVE
assertCmdEmpty "cat ./empty-file"                  "empty-file is not empty!"
assertCmdEq    "cat ./aaaa-file"            "AAaa" "aaaa-file has wrong contents!"
assertCmdEq    "stat -c '%s' ./random-file" "1024" "random-file has wrong size!"

# Verify file modes:
assertCmdEq "stat -c '%a' ./empty-file" "644" "empty-file was stored with unexpected access mode!"
assertCmdEq "stat -c '%a' ./aaaa-file"  "600" "aaaa-file was stored with unexpected access mode!"

success

