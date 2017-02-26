#!/bin/bash
. $(dirname "$0")/init.sh

# This script tests if walk will refuse to create a new archive without the -c option.

ARCHIVE="test-9810994571.tar.gz"

cd_tmpdir
prepare_subshell <<SH
 fail "Walk started a subshell! This should not have happened."
SH

# A non-existing filename (WITHOUT the -c option) should always result in EXIT_NOTFOUND.
assertCmd "$WALK -y $ARCHIVE" $EXIT_NOTFOUND

success

