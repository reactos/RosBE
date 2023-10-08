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
			echo "Your processor architecture is not supported by RosBE"
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

# Downloads a module
# Return 0 if it was downloaded, otherwise 1.
#   Parameter 1: The directory to download the module to
#   Parameter 2: The URL of the module
#   Parameter 3: The file name of the module
rs_download_module()
{
	local target_dir=$1
	local url=$2
	local file=$3

	mkdir -p "$target_dir" 2>/dev/null
	cd "$target_dir"

	if [ ! -f $file ] ; then
		rs_do_command wget -O "$file" -q $url
		rs_check_run 0
	fi

	return 0
}

# Checks whether the given module needs to be processed and if so, extracts it.
# Returns 0 if it needs to be processed, otherwise 1.
#   Parameter 1: The module name
#   Parameter 2: The directory to extract the module to
#	Parameter 3: The extension of the archive
rs_extract_module()
{
	local module=$1
	local target_dir=$2
	local ext=$3

	cd "$target_dir"

	rs_do_command tar -xf "$rs_sourcedir/$module.$ext"

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

# Compares the sha256 of a file with an hash
#	Parameter 1: Name of the file to calculate the hash
#	Parameter 2: Hash to compare
#	Return 0 if everything was ok, otherwise it returns 1
rs_sha256_compare()
{
	hash=`eval sha256sum -- "$1" | cut -d " " -f 1`
	if [ "$hash" = "$2" ] ; then
		return 0
	fi
	
	return 1
}

# Print a message in red color
#   Parameter 1: The message
#   Parameter 2: Optional additional parameters for "echo"
rs_redmsg()
{
	echo -e $2 "\033[31m$1\033[0m"
}

# Strips target module
#   Parameter 1: File to strip
rs_strip_target_module()
{
	if [ "$MSYSTEM" ]; then
		$rs_archprefixdir/bin/${rs_target_tool_prefix}strip -d $1 ";" >& /dev/null
	else
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --only-keep-debug $1 $1.dbg 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --strip-debug $1 2>/dev/null
		$rs_archprefixdir/bin/${rs_target_tool_prefix}objcopy --add-gnu-debuglink=$1.dbg $1 2>/dev/null
	fi
}


# Strips system module
#   Parameter 1: File to strip
rs_strip_os_module()
{
	if [ "$MSYSTEM" ]; then
		$rs_archprefixdir/bin/${rs_target_tool_prefix}strip -d $1 ";" >& /dev/null
	else
		objcopy --only-keep-debug $1 $1.dbg 2>/dev/null
		objcopy --strip-debug $1 2>/dev/null
		objcopy --add-gnu-debuglink=$1.dbg $1 2>/dev/null
	fi
}
