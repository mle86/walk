#!/bin/bash
. $(dirname "$0")/init.sh

# This script tests if walk will deny to create a new archive without the -c option.

ARCHIVE='test.tar.gz'

cd_tmpdir
prepare_subshell <<SH
 fail "Walk started a subshell! This should not have happened."
SH

assertCmd "$WALK -y $ARCHIVE" $EXIT_NOTFOUND

success

