#!/bin/bash
. $(dirname "$0")/init.sh

# This test script checks if walk applies correct modes to the unpacked working directory.

walk_input='n\ny\n'  # don't recreate archive, but delete temp dir

assertUnpackedDirmode () {
	local inputArchiveMode="$1"
	local expectedDirectoryMode="$2"

	cp -- "$HERE/archives/test.tgz" "mode-$inputArchiveMode.tgz"
	add_cleanup "mode-$inputArchiveMode.tgz"
	chmod -- "$inputArchiveMode" "mode-$inputArchiveMode.tgz"

	prepare_subshell <<-EOT
		assertFileMode . "${expectedDirectoryMode#"0"}" \
		  "Unpacked working directory had incorrect mode!  (Archive mode: $inputArchiveMode)"
	EOT

	printf "$walk_input" | "$WALK" "mode-$inputArchiveMode.tgz" >/dev/null  # !
}


cd_tmpdir

assertUnpackedDirmode 0400 0700
assertUnpackedDirmode 0600 0700
assertUnpackedDirmode 0700 0700  # An executable .tgz doesn't make a lot of sense, but it shouldn't break the process either!
assertUnpackedDirmode 0640 0750
assertUnpackedDirmode 0644 0755
assertUnpackedDirmode 0755 0755
assertUnpackedDirmode 0666 0777


success
