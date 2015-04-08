#!/bin/bash
#
##################################################################
#
# Script to package HHVM 3.6 for Ubuntu Trusty
#
#   Author:  Daniel Mikusa
#     Date:  3-3-2015
#
##################################################################
#  Configuration
#
HHVM_VERSION=3.6.1
BUILD_DIR=`pwd`/build
##################################################################
set -e

function download() {
	URL=$1
	NAME=$2
	FILE=$(basename "$URL")
	mkdir -p "$BUILD_DIR/files_$NAME"
	if [ ! -f "$BUILD_DIR/files_$NAME/$FILE" ]; then
		echo -n "    Downloading [$NAME]..."
		curl -s -L -O "$URL"
		mv "$FILE" "$BUILD_DIR/files_$NAME"
		echo " done"
	fi
	echo -n "    Extracting [$NAME]..."
	cd "$BUILD_DIR/files_$NAME"
	ar xf "$FILE"
    if [ -f "data.tar.gz" ]; then
        tar zxf "data.tar.gz"
    elif [ -f "data.tar.xz" ]; then
        tar Jxf "data.tar.xz"
    else
        echo "fail, not found :("
        exit -1
    fi
	rm -f data.tar.gz data.tar.xz control.tar.gz debian-binary _gpgbuilder
	cd ../../
	echo " done"
}

echo "Packaging up HHVM"

# get stuff
#  list comes from here:  https://github.com/heroku/heroku-buildpack-php/blob/master/support/build/hhvm
download "http://dl.hhvm.com/ubuntu/pool/main/h/hhvm/hhvm_$HHVM_VERSION~trusty_amd64.deb" "hhvm"
download "http://mirrors.kernel.org/ubuntu/pool/main/b/boost1.54/libboost-filesystem1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-fs"
download "http://mirrors.kernel.org/ubuntu/pool/main/b/boost1.54/libboost-program-options1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-prog-ops"
download "http://mirrors.kernel.org/ubuntu/pool/main/b/boost1.54/libboost-regex1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-regex"
download "http://mirrors.kernel.org/ubuntu/pool/main/b/boost1.54/libboost-system1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-system"
download "http://mirrors.kernel.org/ubuntu/pool/main/b/boost1.54/libboost-thread1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-thread"
download "http://mirrors.kernel.org/ubuntu/pool/universe/b/boost1.54/libboost-context1.54.0_1.54.0-4ubuntu3.1_amd64.deb" "boost-context"
download "http://mirrors.kernel.org/ubuntu/pool/main/g/google-glog/libgoogle-glog0_0.3.3-2_amd64.deb" "libgoogle"
download "http://mirrors.kernel.org/ubuntu/pool/universe/j/jemalloc/libjemalloc1_3.6.0-3_amd64.deb" "jemalloc"
download "http://mirrors.kernel.org/ubuntu/pool/universe/libo/libonig/libonig2_5.9.6-1_amd64.deb" "libonig"
download "http://mirrors.kernel.org/ubuntu/pool/universe/t/tbb/libtbb2_4.2~20130725-1.1ubuntu1_amd64.deb" "libtbb2"
download "http://mirrors.kernel.org/ubuntu/pool/main/g/gflags/libgflags2_2.0-2.1_amd64.deb" "libgflags"
download "http://mirrors.kernel.org/ubuntu/pool/main/libu/libunwind/libunwind8_1.1-3.2_amd64.deb" "libunwind"
download "http://mirrors.kernel.org/ubuntu/pool/main/g/gcc-4.9/libstdc%2b%2b6_4.9.2-10ubuntu12_amd64.deb" "libstdcpp"

# package up external files
echo -n "    Packaging additional libraries..."
rm -rf "$BUILD_DIR/files_hhvm/etc" "$BUILD_DIR/files_hhvm/var" "$BUILD_DIR/files_hhvm/usr/share"
rm "$BUILD_DIR/files_hhvm/usr/bin/hh_server" \
   "$BUILD_DIR/files_hhvm/usr/bin/hh_client" \
   "$BUILD_DIR/files_hhvm/usr/bin/hack_remove_soft_types" \
   "$BUILD_DIR/files_hhvm/usr/bin/hackificator" \
   "$BUILD_DIR/files_hhvm/usr/bin/h2tp"
cp "/usr/lib/x86_64-linux-gnu/libyaml-0.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_boost-context/usr/lib/x86_64-linux-gnu/libboost_context.so.1.54.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libgmp.so.10" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libMagickWand.so.5" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libMagickCore.so.5" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libjpeg.so.8" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libvpx.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libfreetype.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/libc-client.so.2007e" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libmysqlclient.so.18" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libicui18n.so.52" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libicuuc.so.52" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libcurl.so.4" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_jemalloc/usr/lib/x86_64-linux-gnu/libjemalloc.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_boost-prog-ops/usr/lib/x86_64-linux-gnu/libboost_program_options.so.1.54.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_boost-fs/usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.54.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libevent-2.0.so.5" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libtbb2/usr/lib/libtbb.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libxml2.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libxslt.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libexslt.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libonig/usr/lib/x86_64-linux-gnu/libonig.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/libmcrypt.so.4" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libldap_r-2.4.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/liblber-2.4.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libmemcached.so.10" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libedit.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libelf.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_boost-thread/usr/lib/x86_64-linux-gnu/libboost_thread.so.1.54.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_boost-system/usr/lib/x86_64-linux-gnu/libboost_system.so.1.54.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libgoogle/usr/lib/x86_64-linux-gnu/libglog.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libgflags/usr/lib/x86_64-linux-gnu/libgflags.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libunwind/usr/lib/x86_64-linux-gnu/libunwind.so.8" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "$BUILD_DIR/files_libstdcpp/usr/lib/x86_64-linux-gnu/libstdc++.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libX11.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libgomp.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/liblcms2.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/liblqr-1.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libfftw3.so.3" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libfontconfig.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libXext.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libltdl.so.7" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libkrb5.so.3" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libicudata.so.52" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libidn.so.11" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/librtmp.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libsasl2.so.2" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libgssapi.so.3" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libgnutls.so.26" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libxcb.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libk5crypto.so.3" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libkrb5support.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libheimntlm.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libkrb5.so.26" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libasn1.so.8" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libhcrypto.so.4" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libroken.so.18" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libtasn1.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libp11-kit.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libXau.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libXdmcp.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libwind.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libheimbase.so.1" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libhx509.so.5" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libsqlite3.so.0" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
cp "/usr/lib/x86_64-linux-gnu/libffi.so.6" "$BUILD_DIR/files_hhvm/usr/lib/hhvm/"
echo " done"

# Move directory & zip it up
echo -n "    Creating archive..."
cd "$BUILD_DIR"
mv "files_hhvm" "hhvm"
mkdir -p "files_hhvm"
mv "hhvm/hhvm_$HHVM_VERSION~trusty_amd64.deb" "files_hhvm/"
tar czf "hhvm-$HHVM_VERSION.tar.gz" "hhvm/"
shasum "hhvm-$HHVM_VERSION.tar.gz" > "hhvm-$HHVM_VERSION.tar.gz.sha1"
rm -rf "hhvm/"
cd ../
echo ' done'

# Move packages to the output directory
cd "$BUILD_DIR/../../"
mkdir -p "output/hhvm-$HHVM_VERSION"
mv "$BUILD_DIR/hhvm-$HHVM_VERSION.tar.gz" "output/hhvm-$HHVM_VERSION"
mv "$BUILD_DIR/hhvm-$HHVM_VERSION.tar.gz.sha1" "output/hhvm-$HHVM_VERSION"

echo 'HHVM Build complete.'
