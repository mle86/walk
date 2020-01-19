#!/bin/bash
. $(dirname "$0")/init.sh

# .deb archives are actually .ar archives with a specific file structure.
# We already have test-ar so in here we can focus on the sub-archive handling.


# assertArchiveType ARCHIVEFILE ARCHIVETYPE [COMPRESSIONTYPE]
assertArchiveType () {
	local archive="$1"
	local expectedType="$2"
	local expectedCompression="$3"
	local fileOutput="$(file -Nbz -- "$1" | tr '[A-Z]' '[a-z]')"
	assertContains "$fileOutput" "$expectedType" \
		"Archive $archive is not of correct type"
	[ -n "$expectedCompression" ] && assertContains "$fileOutput" "$expectedCompression" \
		"Archive $archive is not of correct compression type"
	true
}


cd_tmpdir

cp -- "$HERE/archives/test.deb" .
ARCHIVE="$(pwd)/test.deb"
add_cleanup "$ARCHIVE"


prepare_subshell <<SH
	assertCmdEq "cat debian-binary" "2.0"
	[ -f "control.tar.gz/control"  ] || fail "Sub-archive extraction failed!  (control.tar.gz -> control)"
	[ -x "control.tar.gz/postinst" ] || fail "Sub-archive extraction failed!  (data.tar.xz -> postinst*)"
	[ -x "data.tar.xz/bin/mybin"   ] || fail "Sub-archive extraction failed!  (data.tar.xz -> mybin*)"
	assertContains "\$(cat data.tar.xz/bin/mybin)" "foo"

	mv -- data.tar.xz/ data.tar.gz/  # Let's see if walk will correctly re-package this renamed directory.
	rm -- control.tar.gz/postinst

	printf '.TH MYBIN 1 "" "" ""\n.SH NAME\nmybin \- does pretty much nothing.\n' \
	  > data.tar.gz/usr/share/man/man1/mybin.1
SH

assertCmd "$WALK -y $ARCHIVE"
assertSubshellWasExecuted


mkdir extracted/
(
	cd extracted/
	ar xoPU "$ARCHIVE"

	assertCmdEq "cat debian-binary" "2.0"
	[ -f "control.tar.gz" ] || fail "Sub-archive re-creation failed!  (control.tar.gz)"
	[ -f "data.tar.gz"    ] || fail "Sub-archive re-creation failed!  (data.tar.gz)"

	assertArchiveType "control.tar.gz" 'tar archive' 'gzip compressed'
	assertArchiveType "data.tar.gz"    'tar archive' 'gzip compressed'

	mkdir CONTROL/ ; cd CONTROL/ ; tar -zxf ../control.tar.gz ; cd ../
	mkdir DATA/    ; cd DATA/    ; tar -zxf ../data.tar.gz    ; cd ../

	[ -f "CONTROL/control"    ] || fail "Unchanged file no longer present in re-created archive!"
	! [ -f "CONTROL/postinst" ] || fail "Deleted file still found in re-created archive!"
	assertContains "$(cat "DATA/usr/share/man/man1/mybin.1")" ".TH MYBIN 1" \
		"New file not correctly stored in re-created archive!"
)
rm -rf -- extracted/


success
