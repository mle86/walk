#!/bin/sh
. $(dirname "$0")/init.sh

# This script tests if archives with varying owner information
# can be unpacked and re-packed.
# This works fine if the user is root --
# but a non-root user cannot change the owner UID.
# Walk should continue anyway, discarding the owner information.

[ "$(id -u)" -eq 0 ] && skip "This test cannot be run as root."

cd_tmpdir

prepare_archive () {
	local filename="$1"
	ARCHIVE="$DIR/$filename"
	cp "$HERE/archives/$filename" "$ARCHIVE"
	add_cleanup "$ARCHIVE"
}
test_archive () {
	local filename="$1"
	prepare_archive "$filename"
	prepare_subshell <<-SH
		# All test archives have the same contents:
		assertCmdEq "cat a/aa" "A"
		assertCmdEq "cat b/bb" "B"
		assertCmdEq "cat c/cc" "C"
SH
	assertCmd "$WALK -y $ARCHIVE"
	assertSubshellWasExecuted
}


test_archive "different-owners.tar.gz"
test_archive "different-owners.zip"
test_archive "different-owners.cpio"


success

