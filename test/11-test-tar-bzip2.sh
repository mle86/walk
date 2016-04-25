#!/bin/bash
. $(dirname "$0")/init.sh

ARCHIVE='test.tar.bz2'

cd_tmpdir
prepare_standard_archive
tar -cjf $ARCHIVE $STDFILES
delete_standard_archive_files

prepare_subshell <<SH
 verify_standard_archive
 modify_standard_archive
SH

assertCmd "$WALK -y $ARCHIVE"

tar -xjf $ARCHIVE
verify_modified_standard_archive

success

