#!/bin/sh
. $(dirname "$0")/init.sh

# This script creates a file that is of no known archive file type,
# then checks if walk will fail with the correct exit status.


cd_tmpdir
prepare_subshell <<-SH
	fail "Walk started a subshell for an archive of unknown type!"
SH

ARCHIVE='unknown-archive.xyz'
printf '\0\0\0\0' > "$ARCHIVE"


assertCmd "$WALK -y $ARCHIVE" $EXIT_UNKNOWNTYPE


success

