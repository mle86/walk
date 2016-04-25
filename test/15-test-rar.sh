#!/bin/bash
. $(dirname "$0")/init.sh

ARCHIVE='test.zip'

cd_tmpdir
prepare_standard_archive
rar a -r $ARCHIVE $STDFILES
delete_standard_archive_files

prepare_subshell <<SH
 verify_standard_archive
 modify_standard_archive
SH

assertCmd "$WALK -y $ARCHIVE"

rar x $ARCHIVE
verify_modified_standard_archive

success
