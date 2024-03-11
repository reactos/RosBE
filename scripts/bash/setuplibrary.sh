###############################################################################
# Shared setup functions for RosBE-Windows' buildtoolchain and RosBE-Unix
# Copyright 2009-2020 Colin Finck <colin@reactos.org>
#
# Released under GPL-2.0-or-later (https://spdx.org/licenses/GPL-2.0-or-later)
###############################################################################
# Conventions:
#   - Prepend all functions of this library with "rs_" (RosBE Setup)
#   - Also prepend all variables used here and variables which are shared
#     between buildtoolchain and RosBE-Unix and are used in conjunction with
#     these functions in the calling script with "rs_"
###############################################################################


# Print a message in a bold font
#   Parameter 1: The message
#   Parameter 2: Optional additional parameters for "echo"
rs_boldmsg()
{
	echo -e $2 "\033[1m$1\033[0m"
}

# Check for several requirements, which need to be met in order to run the installation script properly
rs_check_requirements()
{
	# Check for the processor architecture
	local cpuarch=`uname -m`
	case "$cpuarch" in
		"i686")
			rs_abi=32
			;;
		"x86_64" | "amd64")
			rs_abi=64
			;;
		*)
			echo "Your processor architecture is not supported by RosBE-Unix!"
			exit 1;;
	esac

	# Test if the script directory is writable
	if [ ! -w "$rs_scriptdir" ]; then
		rs_redmsg "The script directory \"$rs_scriptdir\" is not writable, aborted!"
		exit 1
	fi

	# Test if the script directory contains spaces
	case "$rs_scriptdir" in
	*" "*)
		rs_redmsg "The script directory \"$rs_scriptdir\" contains spaces!"
		rs_redmsg "Therefore some build tools cannot be compiled properly."
		echo
		rs_redmsg "Please move \"$rs_scriptdir\" to a directory, which does not contain spaces."

		exit 1;;
	esac

	# Check if all necessary tools exist
	rs_boldmsg "Checking for the needed tools..."

	local toolmissing=false
	for tool in $rs_needed_tools; do
		echo -n "Checking for $tool... "

		if which "$tool" >& /dev/null; then
			rs_greenmsg "OK"
		else
			rs_redmsg "MISSING"
			toolmissing=true
		fi
	done

	# Special check for GNU Make
	# For example FreeBSD's "make" is not GNU Make, so we have to define a variable
	echo -n "Checking for GNU Make... "

	local app
	local checkapps="make gmake"
	rs_makecmd=""

	for app in $checkapps; do
		if $app -v 2>&1 | grep "GNU Make" >& /dev/null; then
			# Store the complete path in $rs_makecmd to prevent collisions with our own Make.
			rs_makecmd=`which $app`
			rs_greenmsg "OK"
		fi
	done

	if [ "$rs_makecmd" = "" ]; then
		rs_redmsg "MISSING"
		toolmissing=true
	fi

	# Check for libs
	# Skip that part on OSX and MSYS
	if [ "`uname`" != "Darwin" ] && [ "`uname -o`" != "Msys" ]; then
		# pkg-config needs to be installed to check for libs
		echo -n "Checking for pkg-config... "

		if which pkg-config >& /dev/null; then
			rs_greenmsg "OK"
		else
			rs_redmsg "MISSING"
			toolmissing=true
		fi

		for lib in $rs_needed_libs; do
			echo -n "Checking for $lib... "

			if pkg-config --exists $lib >& /dev/null; then
				rs_greenmsg "OK"
			else
				if which pkg-config >& /dev/null; then
					rs_redmsg "MISSING"
				else
					rs_redmsg "UNABLE TO DETERMINE"
				fi
				toolmissing=true
			fi
		done
	fi

	if $toolmissing; then
		echo "At least one needed tool is missing, aborted!"
		exit 1
	fi

	echo
}

# Check whether the previous command finished with errorlevel 0
# If it did so, print a green "OK" and delete the debug logfile for the command.
# If that wasn't the case, print a red "FAILED" and give information about the debug logfile.
rs_check_run()
{
	if [ $? -ne 0 ]; then
		rs_redmsg "FAILED"
		echo "Please take a look at the log file \"$rs_workdir/build.log\""
		echo "If you did not do something wrong, please save the log file and contact the ReactOS Team."

		echo "Aborted!"
		exit 1
	else
		rs_greenmsg "OK"
		rm "$rs_workdir/build.log"
	fi
}

# Cleans a module prepared with rs_prepare_module.
#   Parameter 1: The module name
rs_clean_module()
{
	echo "Cleaning up $1..."
	cd "$rs_workdir"
	rm -rf "$1-build"
	rm -rf "$1"
}

# Executes a building command and checks whether it succeeded.
# Terminates the building process in case of failure.
#   Parameters: The command to execute including parameters
rs_do_command()
{
	echo -n "Running \"$*\"... "
	$* >& "$rs_workdir/build.log"
	rs_check_run
}

# Checks whether the given module needs to be processed and if so, extracts it.
# Returns 0 if it needs to be processed, otherwise 1.
#   Parameter 1: The module name
#   Parameter 2: The directory to extract the module to
rs_extract_module()
{
	local module=$1
	local target_dir=$2

	cd "$target_dir"

	echo -n "Extracting $module... "

	# Extract with bunzip2 and tar instead of "tar xjf" due to https://github.com/msys2/MSYS2-packages/issues/1548
	bunzip2 --decompress --stdout "$rs_sourcedir/$module.tar.bz2" | tar -x --file=- >& "$rs_workdir/build.log"
	rs_check_run 0

	return 0
}

# Print a message in green color
#   Parameter 1: The message
#   Parameter 2: Optional additional parameters for "echo"
rs_greenmsg()
{
	echo -e $2 "\033[32m$1\033[0m"
}

# Print a message in yellow color
#   Parameter 1: The message
#   Parameter 2: Optional additional parameters for "echo"
rs_yellowmsg()
{
	echo -e $2 "\033[33m$1\033[0m"
}

# Checks whether the given module needs to be processed and if so, extracts it into a dedicated build directory
# Returns 0 if it needs to be built, otherwise 1.
#   Parameter 1: The module name
rs_prepare_module()
{
	local module=$1

	if ! `eval echo \\$rs_process_$module`; then
		return 1
	fi

	rm -rf "$rs_workdir/$module"
	rs_extract_module "$module" "$rs_workdir"

	rm -rf "$module-build"
	mkdir "$module-build"
	cd "$module-build"

	return 0
}

# Print a message in red color
#   Parameter 1: The message
#   Parameter 2: Optional additional parameters for "echo"
rs_redmsg()
{
	echo -e $2 "\033[31m$1\033[0m"
}

