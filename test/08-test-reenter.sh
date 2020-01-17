#!/bin/bash
. $(dirname "$0")/init.sh

# This script tests if walk can re-enter a previously-entered archive --
# that means there's an archive-like named directory
# and the original archive (renamed to be hidden) is also there.

ARCHIVE=test.tar
cd_tmpdir


# First, create a standard archive from scratch:
mkdir t/
cd t/
prepare_standard_archive
find -type f -print0 | xargs -0 tar -cf ../$ARCHIVE
cd ../
rm -rf t/

# There is now a "test.tar" archive with standard contents.


# Now enter it with walk,
# and kill the walk script
# before it can re-pack the archive and rename the hidden original archive file:
prepare_subshell <<SH_KILL
	verify_standard_archive

	kill -TERM \$PPID
SH_KILL
assertCmd "$WALK -y $ARCHIVE" 143
assertSubshellWasExecuted
# 143 = 128+SIGTERM

# The archive should now be renamed and there should be a directory in its place.
[ ! -f $ARCHIVE  ] || fail "The custom-built archive file $ARCHIVE is still there!"
[   -d $ARCHIVE/ ] || fail "The custom-built archive file $ARCHIVE file is gone, but there is no $ARCHIVE/ working directory either!"


# Now try to re-enter the directory:
prepare_subshell <<SH_REENTRY
	verify_standard_archive
	modify_standard_archive
SH_REENTRY
assertCmd "$WALK -y $ARCHIVE"
assertSubshellWasExecuted

# The archive should now be a file again!
[ ! -d $ARCHIVE/ ] || fail "After re-entering, the archive directory $ARCHIVE/ is still there!"
[   -f $ARCHIVE  ] || fail "After re-entering, the archive directory is deleted, but there is no $ARCHIVE file either!"


# Finally, make sure the re-entry process did not mess with re-packing:
prepare_subshell <<SH_VERIFY
	verify_modified_standard_archive
SH_VERIFY
assertCmd "$WALK -y $ARCHIVE"
assertSubshellWasExecuted


success

