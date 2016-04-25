#!/bin/bash
. $(dirname "$0")/init.sh

ARCHIVE='test.7z'

cd_tmpdir
prepare_standard_archive
7zr a -bd $ARCHIVE $STDFILES
delete_standard_archive_files
rm -fd $RMSTDFILES

prepare_subshell <<SH
 verify_standard_archive
 modify_standard_archive
SH

assertCmd "$WALK -y $ARCHIVE"

7zr x $ARCHIVE
verify_modified_standard_archive

success

