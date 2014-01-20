#!/bin/bash
#
##################################################################
#
# Script to build Nginx 1.5 for use with CloudFoundry
#
#   Author:  Daniel Mikusa
#     Date:  01-19-2014
#
##################################################################
#  Configuration
#
NGINX_VERSION=1.5.8
# location where files are built
INSTALL_DIR="/tmp/staged/app"
BUILD_DIR=`pwd`/build
##################################################################
set -e

function build_nginx_15() {
	cd "$BUILD_DIR"
	if [ "n$NGINX_VERSION" == "n" ]; then
		NGINX_VERSION=2.4.6
	fi
	if [ ! -d "nginx-$NGINX_VERSION" ]; then
		curl -L -O "http://nginx.org/download/nginx-1.5.8.tar.gz"
		tar zxf "nginx-$NGINX_VERSION.tar.gz"
		rm "nginx-$NGINX_VERSION.tar.gz"
	fi
	cd "nginx-$NGINX_VERSION"
	./configure \
                --prefix="$INSTALL_DIR/nginx" \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_auth_request_module \
		--with-http_random_index_module \
		--with-http_secure_link_module \
		--with-http_stub_status_module \
		--without-http_uwsgi_module \
		--without-http_scgi_module \
		--with-pcre \
		--with-pcre-jit
	make -j 3
	make install
	cd "$BUILD_DIR"
}

# clean up previous work
rm -rf "$INSTALL_DIR"

# setup build directory
if [ ! -d "$BUILD_DIR" ]; then
	mkdir "$BUILD_DIR"
fi

# build required libs & httpd
build_nginx_15

# Remove unnecessary files and config
cd "$INSTALL_DIR/nginx"
rm -rf html/ conf/scgi_params* conf/uwsgi_params* conf/*.default
rm -rf conf/koi-* conf/win-utf

# Package the binary
cd "$INSTALL_DIR"
tar czf "nginx-$NGINX_VERSION.tar.gz" nginx
shasum "nginx-$NGINX_VERSION.tar.gz" > "nginx-$NGINX_VERSION.tar.gz.sha1"

# Move packages to this directory
cd "$BUILD_DIR/../"
mkdir -p "nginx-$NGINX_VERSION"
mv /tmp/staged/app/nginx-*.gz "nginx-$NGINX_VERSION"
mv /tmp/staged/app/nginx-*.gz.sha1 "nginx-$NGINX_VERSION"

echo "Done!"
