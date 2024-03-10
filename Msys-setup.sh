cd `dirname $0`
rs_rootdir="$PWD"

source "$rs_rootdir/scripts/setuplibrary.sh"

if [ ! "$MSYSTEM" ] ; then
    rs_redmsg "You cannot run this script in a normal bash environment"
    echo "This script is designed to work only with MSYS2"
    exit 1
fi

rs_updated=false

# Install required tools in MSYS2
rs_boldmsg "Running MSYS pacman..."
pacman -S --quiet --noconfirm --needed diffutils help2man make msys2-runtime-devel python texinfo tar autoconf automake gcc zlib gettext-devel gettext patch libtool unzip re2c | tee /tmp/buildtoolchain-pacman.log

if grep installation /tmp/buildtoolchain-pacman.log >& /dev/null; then
    rs_updated=true
fi

if [ "$rs_api" = "32" ] ; then
    pacman -S --quiet --noconfirm --needed mingw-w64-i686-zlib mingw-w64-i386-gettext mingw-w64-i686-gcc mingw-w64-i686-libsystre mingw-w64-i686-python
else 
    pacman -S --quiet --noconfirm --needed mingw-w64-x86_64-zlib mingw-w64-x86_64-gettext mingw-w64-x86_64-gcc mingw-w64-x86_64-libsystre mingw-w64-x86_64-python
fi

if grep installation /tmp/buildtoolchain-pacman.log >& /dev/null; then
    rs_updated=true
fi

if [ $rs_updated = true ] ; then
    # See e.g. https://sourceforge.net/p/msys2/tickets/74/
    echo
    rs_boldmsg "Installed MSYS packages have changed!"
    echo "You can now run \"RosBE-Builder.sh\"."
    exit 1
fi
