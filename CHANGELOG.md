# Changelog


#### next (January 2020)

 - Set `WALK_IN_ARCHIVE` env var to opened archive filename


#### v2.3.0 (January 2020)

 - Set safe working directory access mode
 - Support .deb packages
 - Add .ar archive type recognition
 - Support option `-q` (quiet)'

#### v2.2.1 (January 2020)

 - Minor documentation cleanup

#### v2.2.0 (May 2018)

 - Readme cleanup
 - Travis CI

#### v2.1.0 (May 2017)

 - Support re-entry into previously-unpacked archive directory
 - Support direct entry into directory with archive-like name
 - Improved .7z support (use 7z/7zr/7za archiver as available)
 - Fix minor no-recreate bug
 - Fix .jar archive type recognition

#### v2.0.2 (February 2017)

 - Fix `-c` archive creation for 7z/zip/rar/ar
 - Fix non-root extracting of zip archives with different file owners
 - Preserve owner/mode/timestamps in .a archives (ar)
 - Delete incompletely unpacked directories on unpacking errors
 - Correct error message for non-existing archives

#### v2.0.1 (May 2016)

 - Repo cleanup

#### v2.0 (April 2016)

 - Added `-y` option
 - Added `-A` option
 - Fixed .zip re-packing
 - Fixed .7z, .rar, .a unpacking
 - Cleanup of archiver options

#### v1.2.1 (January 2015)

 - Added .jar support
 - Fixed .tar creation

#### v1.2 (January 2015)

 - New `-c` option allows creating empty archives
 - Fixed relative directory handling
 - Removed bash dependency

#### v1.1 (February 2012)

 - Added xz and tar types

#### v1.0 (September 2010)

 - Added archive file type recognition

#### v0.9 (June 2010)

