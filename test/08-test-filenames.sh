#!/bin/bash
. $(dirname "$0")/init.sh

# This test script checks if walk treats special filenames correctly (dots, spaces, quotes).

ARCHIVE='test.tar'
counter=0

cd_tmpdir

# Build initial archive:
echo "$counter" > counter-file
tar -cf "$ARCHIVE" counter-file
rm -f counter-file

test_special_name () {
	local original_name="$ARCHIVE"
	ARCHIVE="$1"
	mv -- "$original_name" "$ARCHIVE"

	prepare_subshell <<SH
	 assertCmdEq "pwd" "$DIR/$ARCHIVE" "Unexpected location!"
	 [ -s counter-file ] || fail "The archived file is missing! Are we really in the correct directory? (Archive name: '$ARCHIVE')"
	 assertCmdEq "cat counter-file" "$counter" "Counter file mismatch -- has the archive been repacked correctly?"
	 echo "$(($counter + 1))" > counter-file
SH

	counter="$(($counter + 1))"

	# Don't use assertCmd() here, it might not handle special characters correctly.
	# So we'll call walk manually, which also means we'll have to check the errcond file ourselves.
	$WALK -y "$ARCHIVE" || fail "Command failed: walk '$ARCHIVE'"
	[ ! -e "$ERRCOND" ] || fail "Command failed: walk '$ARCHIVE'"

	[ -e "$ARCHIVE" ] || fail "Archive does not exist anymore after calling walk: '$ARCHIVE'"
}

test_special_name "test with multiple   spaces.tar"
test_special_name ".hidden	test	with	tabs.tar"
test_special_name "test'apostrophe.tar"
test_special_name "-j looksLikeAnOption.tar"
test_special_name "-- double -- dash.tar"

success

