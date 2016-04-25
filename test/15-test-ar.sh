#!/bin/bash
. $(dirname "$0")/init.sh

ARCHIVE='test.ar'

cd_tmpdir
prepare_standard_archive
find $STDFILES -type f | xargs ar r $ARCHIVE
delete_standard_archive_files

prepare_subshell <<SH
 restore_flattened_standard_archive  # ar does not do subdirectories.
 verify_standard_archive
 modify_standard_archive
SH

assertCmd "$WALK -y $ARCHIVE"

ar x $ARCHIVE
restore_flattened_standard_archive  # ar does not do subdirectories.
verify_modified_standard_archive

success

