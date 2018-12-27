# Shared functions for RosBE-Unix components
# Part of RosBE for Unix-based Operating Systems
# Copyright 2009-2012 Colin Finck <colin@reactos.org>
#                     Pierre Schweitzer <pierre@reactos.org>
#
# Released under GNU GPL v2 or any later version.

# Check whether the given architecture is supported and if so, change the ROS_ARCH variable appropriately
#   Parameter 1: The architecture to set
change_architecture()
{
	local new_arch="$1"

	if [ -f "$_ROSBE_ROSSCRIPTDIR/$new_arch/version.sh" ]; then
		# Architecture parameter seems valid
		ROS_ARCH="$new_arch"
	else
		echo "Unsupported architecture specified, falling back to i386!"
		echo
		ROS_ARCH="i386"
	fi

	export PATH="$_ROSBE_ROSSCRIPTDIR/$ROS_ARCH/bin:$_ROSBE_OLDPATH"
	export ROS_ARCH
}

# Check whether we're running as root and warn the user in case we don't
check_root()
{
	if [ ! "`whoami`" = "root" ]; then
		rs_boldmsg "User is not \"root\""

		echo "The default installation path for the Build Environment is \"$DEFAULT_INSTALL_DIR\"."
		echo "Therefore it is recommended to run this script as the \"root\" user. Otherwise you probably cannot create the necessary directories."
		echo "An alternative is to specify another installation directory at the installation process."
		echo "Do you really want to continue? (yes/no)"

		local answer
		read -p "[no] " answer

		if [[ "$answer" = [yY][eE][sS] ]]; then
			echo
		else
			exit 1
		fi
	fi
}

# Execute required hooks
# Parameter 1 - type of hooks (ie, dir)
# Parameter 2 - all the arguments passed to build
execute_hooks()
{
	local hook_type="$1"
	shift

	echo "Executing $hook_type hooks"

	for file in `ls -1 $_ROSBE_ROSSCRIPTDIR/$hook_type/ | grep [[:digit:]]-*.sh`; do
		$_ROSBE_ROSSCRIPTDIR/$hook_type/$file $*
	done
}
