# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

name = "SDL2_gfx"
version = v"2.0.27"

# Collection of sources required to complete build
sources = [
    "http://www.ferzkopp.net/Software/SDL2_gfx/SDL2_gfx-$(version).tar.gz" =>
    "a4066bd467c96469935a4b1fe472893393e7d74e45f95d59f69726784befd8f8",
    "./bundled",
]

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/SDL2_gfx-*

FLAGS=()
if [[ "${target}" != *86* ]]; then
    FLAGS+=(--enable-mmx=no)
fi
if [[ "${target}" == powerpc64le-* ]] || [[ "${target}" == *-freebsd* ]]; then
    atomic_patch -p1 ../patches/configure_in_add_macro_dir.patch
    autoreconf -vi
    ./autogen.sh
fi

update_configure_scripts
./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} "${FLAGS[@]}"
make -j${nproc}
make install
if [[ "${target}" == *-mingw* ]]; then
    # The shared library is not built for Windows, let's do it ourselves
    cd "${prefix}/lib"
    ar x libSDL2_gfx.a
    cc -shared -o "${libdir}/SDL2_gfx.${dlext}" *.o -lSDL2
    rm *.o
fi
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms()


# The products that we will ensure are always built
products = [
    LibraryProduct(["libSDL2_gfx", "SDL2_gfx"], :libsdl2_gfx)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    PackageSpec(name="SDL2_jll", uuid="ab825dc5-c88e-5901-9575-1e5e20358fcf")
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6")
