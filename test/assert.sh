#!/bin/sh

EXIT_ASSERT=99

ASSERTCMDOUTPUT=

color_info='[1;37m'
color_success='[1;32m'
color_error='[1;31m'
color_normal='[0m'


# If this file was sources by init.sh, that script will overwrite cleanup() soon with its own implementation.
# But if we're running inside a subshell, we don't need any cleanup, so we'll just leave in this empty function.
cleanup () { :; }

abort () {
	# If this is called from a test.sh script, we should simply call cleanup and exit.
	# But if this is called from a walk subshell, we should signal the error condition to the test.sh script running outside!
	[ -n "$IN_SUBSHELL" -a -n "$ERRCOND" ] && touch $ERRCOND
	cleanup
	exit $EXIT_ASSERT
}

err () {
	# 1=errmsg
	echo "${color_error}""$@""${color_normal}" >&2
}

fail () {
	# 1=errmsg
	err "$@"
	abort
}

assertCmd () {
	# assertCmd command [expectedReturnStatus=0]
	# Will save command stdout in $ASSERTCMDOUTPUT, will NOT redirect stderr.
	local cmd="$1"
	local expectedReturnStatus="${2:-0}"

	ASSERTCMDOUTPUT=

	# run the command, save the return status and output,
	# and don't fail, no matter what the return status is!
	if ASSERTCMDOUTPUT="$(echo "$cmd" | sh -s)"; then
		local status="$?"  # ok
	else
		local status="$?"  # also ok
	fi

	# This assertCmd() call might have been the real 'walk' call.
	# In this case, we must check if the 'errcond' file was created.
	if [ -n "$ERRCOND" -a -f "$ERRCOND" ]; then
		# There already has been an error message.
		# No need to check the command status/output anymore.
		abort
	fi

	local isStatusError=
	if [ "$expectedReturnStatus" = "any" ]; then
		# "any" means to accept all return status values -- except 126 and 127,
		# those come from the shell, usually due to an invalid command.
		[ "$status" -eq 126 -o "$status" -eq 127 ] && isStatusError=yes
	elif [ "$status" -ne "$expectedReturnStatus" ]; then
		# status mismatch
		isStatusError=yes
	fi

	if [ -n "$isStatusError" ]; then
		err "Command '$cmd' was not executed successfully!"
		err "(Expected return status: $expectedReturnStatus, Actual: $status)"
		abort
	fi
}

assertEq () {
	# assertEq valueActual valueExpected [errorMessage]
	local valueActual="$1"
	local valueExpected="$2"
	local errorMessage="${3:-"Equality assertion failed!"}"
	if [ "$valueActual" != "$valueExpected" ]; then
		err "$errorMessage"
		err "(Expected: '$valueExpected', Actual: '$valueActual')"
		abort
	fi
}

assertEmpty () {
	# assertEmpty valueActual [errorMessage]
	local valueActual="$1"
	local errorMessage="${2:-"Emptyness assertion failed!"}"
	assertEq "$valueActual" "" "$errorMessage"
}

assertCmdEq () {
	# assertCmdEq command expectedOutput [errorMessage]
	local cmd="$1"
	local expectedOutput="$2"
	local errorMessage="${3:-"Command output assertion failed!"}"

	assertCmd "$cmd" 0  # run cmd, check success return status
	assertEq "$ASSERTCMDOUTPUT" "$expectedOutput" "$errorMessage"  # compare output
}

assertCmdEmpty () {
	# assertCmdEmpty command [errorMessage]
	local cmd="$1"
	local errorMessage="${2:-"Command output emptyness assertion failed!"}"

	assertCmdEq "$cmd" "$expectedReturnStatus" "" "$errorMessage"
}

assertFileSize () {
	# assertFileSize fileName expectedSize [errorMessage]
	local fileName="$1"
	local expectedSize="$2"
	local errorMessage="${3:-"File '$fileName' has wrong size!"}"

	assertCmdEq "stat --format='%s' '$fileName'" "$expectedSize" "$errorMessage"
}

assertFileMode () {
	# assertFileMode fileName expectedOctalMode [errorMessage]
	local fileName="$1"
	local expectedOctalMode="$2"
	local errorMessage="${3:-"File '$fileName' has wrong access mode!"}"

	assertCmdEq "stat --format='%a' '$fileName'" "$expectedOctalMode" "$errorMessage"
}

