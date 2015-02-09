#!/bin/bash

ROOT=`pwd`
BUILD=$ROOT/build/zk
BUILD_TMP=$BUILD/tmp
DEPS=$ROOT/deps
PLATFORM=`uname`
ZK_VERSION=3.4.6
ZK=$BUILD_TMP/zookeeper-$ZK_VERSION
ZK_FILE=$DEPS/zookeeper-$ZK_VERSION.tar.gz
PATCHES=$(ls $DEPS/*.patch)

if [ "$PLATFORM" != "SunOS" ]; then
    if [ -e "$BUILD/lib/libzookeeper_st.la" ]; then
        echo "ZooKeeper has already been built"
        exit 0
    fi

    mkdir -p $BUILD_TMP

    cd $BUILD_TMP

    tar -zxf $ZK_FILE

    cd $ZK

    echo "Applying patches"
    for PATCH in $PATCHES; do
        echo "Patching: $PATCH"
        patch -p0 < $PATCH
        if [ $? != 0 ] ; then
                echo "Unable to patch the ZooKeeper source"
                exit 1
        fi
    done

    cd $ZK/src/c && \
    ./configure \
        --without-syncapi \
        --enable-static \
        --disable-shared \
        --with-pic \
        --libdir=$BUILD/lib \
        --prefix=$BUILD && \
        make && \
        make install
    if [ $? != 0 ] ; then
            echo "Unable to build zookeeper library"
            exit 1
    fi
    cd $ROOT

    # At this point, the binaries have been built and copied
    # into the --prefix directory, so the temp files from the build
    # can be cleaned up
    rm -Rf $BUILD_TMP
else
    if [ `uname -v` =~ "joyent_.*" ] ; then
        pkgin list | grep zookeeper-client-$ZK_VERSION
        if [ $? != 0] ; then
            echo "You must install zookeeper before installing this module. Try:"
            echo "pkgin install zookeeper-client-$ZK_VERSION"
            exit 1
        fi
    fi
fi
