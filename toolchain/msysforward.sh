# Set up host args

rs_host_cflags="${CFLAGS:--pipe -O2 -g0 -march=native}"
rs_host_cxxflags="${CXXFLAGS:-$rs_host_cflags}"

rs_host_ar="${AR:-ar}"
rs_host_as="${AS:-as}"
rs_host_cc="${CC:-gcc}"
rs_host_cxx="${CXX:-g++}"
rs_host_dlltool="${DLLTOOL:-dlltool}"
rs_host_ranlib="${RANLIB:-ranlib}"
rs_host_strip="${STRIP:-strip}"

export AR="$rs_host_ar"
export AS="$rs_host_as"
export CC="$rs_host_cc"
export CFLAGS="$rs_host_cflags"
export CXX="$rs_host_cxx"
export CXXFLAGS="$rs_host_cxxflags"
export DLLTOOL="$rs_host_dlltool"
export RANLIB="$rs_host_ranlib"
export STRIP="$rs_host_strip"
export MAKE="make"

# Call the command

echo "$MSYSTEM debug: $*"

$*
