#!/bin/sh
. $(dirname "$0")/init.sh

# This test script checks if walk will use the correct exit status values
# in various error conditions.
# EXIT_NOTFOUND is tested in 00-test-nocreate.
# EXIT_UNKNOWNTYPE is tested in 00-test-unknowntype.
# The more complicated failure states are tested in 08-test-packfail.

cd_tmpdir


# --help should print the usage information and exit with EXIT_HELP (usually 0).
assertCmd "$WALK --help" $EXIT_HELP

# Unknown options should result in EXIT_SYNTAX (usually 1).
assertCmd "$WALK -9I§" $EXIT_SYNTAX

# A non-file argument should result in EXIT_NOTAFILE.
assertCmd "$WALK /dev/null" $EXIT_NOTAFILE


echo foo > ./testfile
tar -cf test.tar ./testfile
cp test.tar test2.tar
add_cleanup test.tar test2.tar testfile

# A double argument (even if valid) should result in EXIT_SYNTAX.
assertCmd "$WALK test.tar test2.tar" $EXIT_SYNTAX
assertCmd "$WALK test.tar test.tar"  $EXIT_SYNTAX


success

