#/bin/bash

set -e

SRC_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
cd $SRC_PATH

source common.sh

if [ "$SNAPCRAFT_PART_INSTALL" != "" ]; then
    INSTALL=$SNAPCRAFT_PART_INSTALL/opt/${PROJECT}
else
    INSTALL=/opt/${PROJECT}-${VERSION}
fi

# Internal variables
CLEAN=0
BUILD_DEPS=0

# Overridable number of build processors
if [ "$NUM_PROCS" == "" ]; then
    NUM_PROCS=$(nproc --all)
fi

# Argument parsing
while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -c|--clean)
            CLEAN=1
            shift
        ;;
        -d|--deps)
            BUILD_DEPS=1
            shift
        ;;
        *)
            echo "usage: $0 [-d|--deps] [-c|--clean]"
            exit 1
        ;;
    esac
done

function build_cmake {
    if [ "$CLEAN" == "1" ]; then
        if [ -d build ]; then
            rm -rf build
        fi
    fi
    if [ ! -d build ]; then
        mkdir build
    fi
    cd build
    if [ -f /usr/bin/dpkg-architecture ]; then
        MULTIARCH=$(/usr/bin/dpkg-architecture -qDEB_TARGET_MULTIARCH)
    else
        MULTIARCH=""
    fi
    PKG_CONF_SYSTEM=/usr/lib/$MULTIARCH/pkgconfig
    PKG_CONF_INSTALL=$INSTALL/lib/pkgconfig:$INSTALL/lib/$MULTIARCH/pkgconfig
    PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PKG_CONF_SYSTEM:$PKG_CONF_INSTALL
    env PKG_CONFIG_PATH=$PKG_CONFIG_PATH LDFLAGS="-L$INSTALL/lib" \
    	cmake .. \
        -DCMAKE_INSTALL_PREFIX=$INSTALL \
        -DCMAKE_MODULE_PATH=$INSTALL \
        -DCMAKE_CXX_FLAGS="-isystem $INSTALL/include -isystem $INSTALL/include/qtmir -L$INSTALL/lib -Wno-deprecated-declarations -Wl,-rpath-link,$INSTALL/lib" \
        -DCMAKE_C_FLAGS="-isystem $INSTALL/include -isystem $INSTALL/include/qtmir -L$INSTALL/lib -Wno-deprecated-declarations -Wl,-rpath-link,$INSTALL/lib" \
        -DCMAKE_LD_FLAGS="-L$INSTALL/lib" \
        -DCMAKE_LIBRARY_PATH=$INSTALL/lib $@
    make VERBOSE=1 -j$NUM_PROCS
    if [ -f /usr/bin/sudo ]; then
        sudo make install
    else
        make install
    fi
}

function build_3rdparty_cmake {
    echo "Building: $1"
    cd $SRC_PATH
    cd 3rdparty/$1
    build_cmake $2
}

function build_project {
    echo "Building project"
    cd $SRC_PATH
    cd src
    build_cmake $1
}

# Install distro-provided dependencies
if [ -f /usr/bin/apt ] && [ -f /usr/bin/sudo ]; then
    bash 3rdparty/apt.sh
elif [ -f /usr/bin/dnf ] && [ -f /usr/bin/sudo ]; then
    bash 3rdparty/dnf.sh
fi

# Build direct dependencies if requested
if [ "$BUILD_DEPS" == "1" ]; then
    # Build direct dependencies
    build_3rdparty_cmake FreeRDP
    build_3rdparty_cmake mir
fi

# Build main sources
build_project
