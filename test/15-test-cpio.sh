#!/bin/bash
. $(dirname "$0")/init.sh

ARCHIVE='test.cpio'

cd_tmpdir
prepare_standard_archive
find $STDFILES -print0 | cpio -0 -o -B -F $ARCHIVE
delete_standard_archive_files

prepare_subshell <<SH
 verify_standard_archive
 modify_standard_archive
SH

assertCmd "$WALK -y $ARCHIVE"

cpio -i --no-absolute-filenames -B -F $ARCHIVE
verify_modified_standard_archive

success

