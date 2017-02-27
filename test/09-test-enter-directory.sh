#!/bin/bash
. $(dirname "$0")/init.sh

# This script tests if walk can enter a directory named like an archive
# and create an archive of the correct type out of it.

ARCHIVE='test.tgz'


cd_tmpdir
mkdir $ARCHIVE/
cd $ARCHIVE/
prepare_standard_archive
cd ../

# There is now a "test.tgz/" directory with standard contents.
# There is NO .test.tgz-WALK-111111-1111 file, so this is not a re-entry case.

# Now see if walk will correctly enter this directory
# and create an archive afterwards:
prepare_subshell <<-SH2
	verify_standard_archive
	modify_standard_archive
SH2
assertCmd "$WALK -y $ARCHIVE/"
assertSubshellWasExecuted

# The temporary directory should be gone, there should be an archive in its place now.
[ -d $ARCHIVE/ ] && fail "Temporary archive directory $ARCHIVE/ is still there!"
[ -f $ARCHIVE  ] || fail "walk did not create new archive $ARCHIVE from re-entered directory!"

# Okay, the archive is there. See if walk used the correct filetype:
file -b  $ARCHIVE | grep -q 'gz.* compressed' || fail "New archive $ARCHIVE has incorrect filetype!"
file -bz $ARCHIVE | grep -q 'tar archive'     || fail "New archive $ARCHIVE has incorrect filetype!"


# See if the contents still match:
prepare_subshell <<-SH3
	verify_modified_standard_archive
SH3
assertCmd "$WALK -y $ARCHIVE"
assertSubshellWasExecuted


success

