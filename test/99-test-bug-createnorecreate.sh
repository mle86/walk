#!/bin/sh
. $(dirname "$0")/init.sh

# This script checks for the no-recreate bug.
# It happens if a user enters a non-existing archive (-c), then chooses to NOT (re-)create the archive.
# (It does not matter whether they answer yes or no to the "delete working directory?" question.)


ARCHIVE='test.tar'
input='n\ny\n'  # DON'T (re-)create the archive. DO delete the working directrory.

cd_tmpdir
prepare_subshell <<SH
	# Actually it's not important what we do inside this archive.
	echo 1234567890 > foo
SH

assertCmd "printf '$input' | $WALK -c $ARCHIVE"

# Since we said "no" to the "re-create archive?" question,
# there should be NO test.tar file now.

[ ! -f "$ARCHIVE" ] || fail "Despite answering 'no' to the 're-create archive?' question, there is now a '$ARCHIVE' file!"
[ ! -e "$ARCHIVE" ] || fail "There is an '$ARCHIVE' file! (although it's not a flat file)"


success

