#!/bin/sh
. $(dirname "$0")/init.sh

# This test script checks if walk will correctly exit after the archiver program failed.

make_mini_archive () {
	echo foo > mini-archive-test-file
	command -p tar -cf "$1" ./mini-archive-test-file
	rm ./mini-archive-test-file
	add_cleanup "$1"
}

cd_tmpdir
ARCHIVE="$DIR/test.tar"
ARCHIVE2="$DIR/test2.tar"
make_mini_archive "$ARCHIVE"
make_mini_archive "$ARCHIVE2"
# Now we have two small tar archives.

mkdir bin/
cat > bin/tar <<-TAR_PROXY
	#!/bin/sh
	# call original tar:
	PATH="$PATH"
	command tar "\$@"
TAR_PROXY
chmod +x bin/tar
add_cleanup bin/tar bin/
export PATH="$DIR/bin/:$PATH"
# In the path, there's now a "tar" script that will fall-back to the real tar -- for now.


################################################################################
# Unpack the archive (this should succeed),
# then try to repack it with a fake tar script (this should fail with EXIT_PACKFAIL).
prepare_subshell <<-SH
	# Don't change the archive contents.

	# Overwrite the fake tar script
	# so it will always fail:
	cat > "$DIR/bin/tar" <<-TAR_FAIL
		#!/bin/sh
		exit 42
TAR_FAIL
SH

assertCmd "$WALK -y $ARCHIVE" "$EXIT_PACKFAIL"
assertSubshellWasExecuted

# Okay, walk correctly fails with EXIT_PACKFAIL if re-packing doesn't work!
# Cleanup, because walk will have kept the working directory:

rm -rf "$ARCHIVE/"


################################################################################
# What about unpacking?
# Our modified bin/tar script will still exit with status 42,
# so the next walk call should fail immediately:

prepare_subshell <<-SH
	fail "This subshell should NOT have been reached!"
SH
assertCmd -v "$WALK -y $ARCHIVE2" "$EXIT_UNPACKFAIL"

# Okay, walk correctly fails with EXIT_UNPACKFAIL if unpacking doesn't work.


success

