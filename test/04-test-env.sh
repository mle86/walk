#!/bin/bash
. $(dirname "$0")/init.sh

# This test script checks if walk correctly sets the required env variables
# when working in an archive.


cd_tmpdir
ARCHIVE="$(readlink -f -- "test1.tar")"

 echo foo > foo-file
 archive_files='./foo-file'
 tar -cf "$ARCHIVE" $archive_files
 rm -f -- $archive_files
 add_cleanup "$ARCHIVE"

 export WALK_IN_ARCHIVE=garbage123456789

prepare_subshell <<SH
	# We're now inside the unpacked archive.

	assertEq "\$WALK_IN_ARCHIVE" "$ARCHIVE" \
	  "walk did not set env var WALK_IN_ARCHIVE correctly!"
SH

assertCmd "$WALK -y $ARCHIVE"



# Okay, but what about a newly-created empty archive?
ARCHIVE="new.tgz"

export WALK_IN_ARCHIVE=
unset WALK_IN_ARCHIVE

prepare_subshell <<SH
	assertEq "\$WALK_IN_ARCHIVE" "$(readlink -f -- "$ARCHIVE")" \
	  "walk did not set env var WALK_IN_ARCHIVE correctly!"
SH

add_cleanup "$ARCHIVE"
assertCmd "$WALK -c -y $ARCHIVE"


success

