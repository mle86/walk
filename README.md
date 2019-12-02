[//]: # (This file was autogenerated from the man page with 'make README.md')

# walk(1) - enter and manipulate archive files like directories

[![Build Status](https://travis-ci.org/mle86/walk.svg?branch=master)](https://travis-ci.org/mle86/walk)


Version 2.2.0, May 2018

<pre><code><b>walk</b> [<b>-cyA</b>] [<b>--</b>] <i>ARCHIVE</i></code></pre>

# Description

**walk** is a shell tool
which allows you to treat archive files as directories.
It completely unpacks an archive file
into a temporary directory named to match the archive filename.
It then spawns a new shell inside the new temporary directory,
where you may proceed with any command line stuff you wish to do.
After leaving this shell,
**walk** asks you if you wish to re-pack the archive
with the contents of the temporary directory (which you may have changed).
This way, you can interactively edit an existing archive,
examine its content, add files to it
and whatever else you wish to do with its contents.

If **walk** is invoked on a non-existing filename or a non-file name
without the **-c** option,
it will print an error and exit.
With the **-c** option, **walk** will accept non-existing filenames
and create a new, empty archive with that name.
This can be used to create new archives from scratch.

# Installation

This is just a shell script, it does not need any compilation.

```# make install```

This will copy the script to /usr/local/bin/**walk**
and the man page to /usr/local/share/man/man.1/**walk.1.gz**.



# Supported File Types

**walk** uses the **file**(1) tool to determine the archive file type.
Currently, it supports handling these file types:

* tar
* tar, compressed with gzip/bzip2/xz
  (requires tar with built-in support for these compression formats,
  i.e. the -zjJ options)
* 7-zip
  (requires **7z**/**7za**/**7zr** binary)
* zip, jar
  (requires **zip** and **unzip** binaries)
* rar
  (requires **rar** binary)
* cpio
  (requires the GNU **cpio** binary)
* ar
  (requires the GNU binutils **ar** binary)

If the **-c** option has been used to create a new empty archive,
the **file** tool cannot be used,
as there is no prior archive file to analyze.
In this case, the type is guessed from the filename extension.
These extensions are recognized:

 .tar,
 .tar.gz, .tgz,
 .tar.bz, .tbz, tar.bz2, .tbz2,
 .tar.xz, .txz,
 .7z,
 .zip, .jar,
 .rar,
 .cpio,
 .a

# Options


* **-c**  
  Create non-existing *ARCHIVE*s
  instead of exiting with an error.
* **-y**  
  Assume \`yes' for the two questions **walk** asks after leaving the subshell.
  This means the original archive will always be recreated,
  and the temporary archive directory will always be removed afterwards. 
* **-A**  
  Store the working directory root (**.**) in the archive,
  not just its contents.
  Not all archivers support this
  (**tar** and **cpio** do).  
  Unpacking archives which contain the **.** directory entry
  can cause the current directory's owner and/or mode to be changed
  by the archiver program,
  so use this option with caution.

# Notes

Beware that some archive types have their own idiosyncracies
concerning file ownership:

* **tar**, **zip**, and **cpio** archives
  can store file owner informations.
  When **walk** is run as non-root,
  the owner informations are silently discarded.
* **a** archives (**ar**(1)) can store owner informations,
  but will always discard them on unpacking.
* **7z** and **rar** archives don't store owner informations.

# Example


<pre><code>mle@box:~$ <b>walk test.tgz</b>
 walk: unpacking archive
 ./httpd.conf
 ./rawdata
 ./uname
 ./subdir/
 ./subdir/a1
 ./subdir/a2
 ./subdir/a3
 walk: starting new shell
mle@box:~/test.tgz$ 
mle@box:~/test.tgz$ <b>ls -la</b>
 drwxr-xr-x  3 mle users 4,0K 2010-09-28 02:44 .
 drwx------ 24 mle users 4,0K 2010-09-28 02:53 ..
 -rw-r-----  1 mle users  30K 2010-09-28 02:42 httpd.conf
 -rw-r--r--  1 mle users 437K 2010-09-28 02:41 rawdata
 drwxr-xr-x  2 mle users 4,0K 2010-09-28 02:45 subdir
 -rwxr-xr-x  1 mle users  14K 2010-09-28 02:44 uname
mle@box:~/test.tgz$ <b>ls -l subdir/</b>
 -rw-r--r-- 1 mle users 300 2010-09-28 02:45 a1
 -rw-r--r-- 1 mle users 400 2010-09-28 02:45 a2
 -rw-r--r-- 1 mle users 500 2010-09-28 02:45 a3
mle@box:~/test.tgz$ <b>rm subdir/a2</b>
mle@box:~/test.tgz$ <b>echo foo > bar</b>
mle@box:~/test.tgz$ <b>>rawdata</b>
mle@box:~/test.tgz$ 
mle@box:~/test.tgz$ <b>exit</b>
 walk: shell terminated.
 walk: Recreate archive test.tgz ? [Y/n]  <b>y</b>
 walk: recreating archive
 ./httpd.conf
 ./bar
 ./rawdata
 ./uname
 ./subdir/
 ./subdir/a1
 ./subdir/a3
 walk: Delete temporary directory? [Y/n]  <b>y</b>
 walk: deleting temp dir
mle@box:~$ 
mle@box:~$ <b>ls -l test*</b>
 -rw-r--r-- 1 mle users 19K 2010-09-28 02:56 test.tgz
mle@box:~$ <b>tar tzvf test.tgz</b>
 -rw-r----- mle/users     30398 2010-09-28 02:42:48 ./httpd.conf
 -rw-r--r-- mle/users         4 2010-09-28 02:55:12 ./bar
 -rw-r--r-- mle/users         0 2010-09-28 02:55:24 ./rawdata
 -rwxr-xr-x mle/users     13900 2010-09-28 02:44:45 ./uname
 drwxr-xr-x mle/users         0 2010-09-28 02:54:50 ./subdir/
 -rw-r--r-- mle/users       300 2010-09-28 02:45:28 ./subdir/a1
 -rw-r--r-- mle/users       500 2010-09-28 02:45:35 ./subdir/a3
</code></pre>

# License

GNU GPL v3

# Author

Maximilian Eul &lt;[maximilian@eul.cc](mailto:maximilian@eul.cc)>
(http://github.com/mle86/walk)
