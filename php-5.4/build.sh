#!/bin/bash
#
##################################################################
#
# Script to build PHP 5.4 for use with CloudFoundry
#
#   Author:  Daniel Mikusa
#     Date:  11-17-2013
#
##################################################################
#  Configuration
#
PHP_VERSION=5.4.22
ZTS_VERSION=20100525
# Third Party Module Versions
RABBITMQ_C_VERSION="0.4.1"
declare -A MODULES
MODULES[APC]="3.1.9"
MODULES[mongo]="1.4.5"
MODULES[redis]="2.2.4"
MODULES[xdebug]="2.2.3"
MODULES[amqp]="1.2.0"
# location where files are built
INSTALL_DIR="/tmp/staged/app"
BUILD_DIR=`pwd`/build
##################################################################
set -e

function build_php54() {
	cd "$BUILD_DIR"
	if [ "n$PHP_VERSION" == "n" ]; then
		PHP_VERSION=5.4.22
	fi
	if [ ! -d "php-$PHP_VERSION" ]; then
		curl -L -o "php-$PHP_VERSION.tar.bz2" "http://us1.php.net/get/php-$PHP_VERSION.tar.bz2/from/us2.php.net/mirror"
		tar jxf "php-$PHP_VERSION.tar.bz2"
		rm "php-$PHP_VERSION.tar.bz2"
	fi
	cd "php-$PHP_VERSION"
	# Investigate these options: --enable-pear, --with-inifile, --with-flatfile, --with-exif
	./configure \
		--prefix="$INSTALL_DIR/php" \
		--with-config-file-path=/home/vcap/app/php/etc \
		--disable-cli \
		--disable-static \
		--enable-shared \
		--enable-ftp \
		--enable-sockets \
		--enable-soap \
		--enable-fileinfo \
		--enable-bcmath \
		--enable-calendar \
		--with-kerberos \
		--enable-zip \
		--without-pear \
		--with-bz2=shared \
		--with-curl=shared \
		--enable-dba=shared \
		--with-cdb \
		--with-gdbm \
		--with-mcrypt=shared \
		--with-mhash=shared \
		--with-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--with-gd=shared \
		--with-pdo-pgsql=shared \
		--with-pgsql=shared \
		--with-pspell=shared \
		--with-gettext=shared \
		--with-gmp=shared \
		--with-imap=shared \
		--with-imap-ssl=shared \
		--with-ldap=shared \
		--with-ldap-sasl \
		--enable-mbstring \
		--enable-mbregex \
		--enable-exif \
		--with-openssl=shared \
		--enable-fpm
	make
	make install
	cd "$BUILD_DIR"
}

build_librabbit() {
	cd "$BUILD_DIR"
	if [ ! -d "rabbitmq-c-$RABBITMQ_C_VERSION" ]; then
                curl -L -O "https://github.com/alanxz/rabbitmq-c/releases/download/v$RABBITMQ_C_VERSION/rabbitmq-c-$RABBITMQ_C_VERSION.tar.gz"
                tar zxf "rabbitmq-c-$RABBITMQ_C_VERSION.tar.gz"
                rm "rabbitmq-c-$RABBITMQ_C_VERSION.tar.gz"
        fi
	cd "rabbitmq-c-$RABBITMQ_C_VERSION"
	./configure --prefix="$INSTALL_DIR/librmq-$RABBITMQ_C_VERSION"
	make
	make install
	cd "$BUILD_DIR"
}

build_external_extension() {
	cd "$BUILD_DIR"
	NAME=$1
	VERSION="${MODULES["$NAME"]}"
	if [ "$NAME" == "amqp" ]; then
		build_librabbit
	fi
	if [ ! -d "$NAME-$VERSION" ]; then
                curl -L -O "http://pecl.php.net/get/$NAME-$VERSION.tgz"
                tar zxf "$NAME-$VERSION.tgz"
                rm "$NAME-$VERSION.tgz"
		rm package.xml
        fi
	cd "$NAME-$VERSION"
	"$INSTALL_DIR/php/bin/phpize"
	if [ "$NAME" == "amqp" ]; then
		./configure --with-php-config="$INSTALL_DIR/php/bin/php-config" --with-librabbitmq-dir="$INSTALL_DIR/librmq-$RABBITMQ_C_VERSION"
	else
		./configure --with-php-config="$INSTALL_DIR/php/bin/php-config"
	fi
	make
	make install
	cd "$BUILD_DIR"
}

build_external_extensions() {
	for MODULE in "${!MODULES[@]}"; do
		build_external_extension "$MODULE"
	done
}

package_php_extension() {
	cd "$INSTALL_DIR"
	NAME=$1
	tar cf "php-$NAME-$PHP_VERSION.tar" "php/lib/php/extensions/no-debug-non-zts-$ZTS_VERSION/$NAME.so"
	if [ $# -gt 1 ]; then
		for FILE in "${@:2}"; do
			if [[ $FILE == /* ]]; then
				cp $FILE php/lib
				FILE=`basename $FILE`
			else
				cp "/usr/lib/$FILE" php/lib/
			fi
			tar rf "php-$NAME-$PHP_VERSION.tar" "php/lib/$FILE"
		done
	fi
	gzip -f -9 "php-$NAME-$PHP_VERSION.tar"
	shasum "php-$NAME-$PHP_VERSION.tar.gz" > "php-$NAME-$PHP_VERSION.tar.gz.sha1"
	cd "$INSTALL_DIR"
}

package_php_extensions() {
	cd "$INSTALL_DIR"
	package_php_extension "bz2"
	package_php_extension "curl"
	package_php_extension "dba"
	package_php_extension "gd"
	package_php_extension "gettext"
	package_php_extension "gmp"
	package_php_extension "ldap"
	package_php_extension "openssl"
	package_php_extension "pdo_pgsql"
	package_php_extension "pgsql"
	package_php_extension "imap" "libc-client.so.2007e"
	package_php_extension "mcrypt" "libmcrypt.so.4"
	package_php_extension "pspell" "libaspell.so.15" "libpspell.so.15"
	# package third party extensions
	package_php_extension "apc"
	package_php_extension "mongo"
	package_php_extension "redis"
	package_php_extension "xdebug"
	package_php_extension "amqp" "$INSTALL_DIR/librmq-$RABBITMQ_C_VERSION/lib/librabbitmq.so.1"
	# remove packaged files
	rm php/lib/lib*
	rm php/lib/php/extensions/no-debug-non-zts-$ZTS_VERSION/*
	cd "$INSTALL_DIR"
}

package_php_fpm() {
	cd "$INSTALL_DIR"
	tar czf "php-fpm-$PHP_VERSION.tar.gz" php/sbin php/php/fpm
	shasum "php-fpm-$PHP_VERSION.tar.gz" > "php-fpm-$PHP_VERSION.tar.gz.sha1"
	rm php/sbin/*
	rm -rf php/php/fpm
	cd "$INSTALL_DIR"
}

package_php() {
	cd "$INSTALL_DIR"
	tar czf "php-$PHP_VERSION.tar.gz" "php"
	shasum "php-$PHP_VERSION.tar.gz" > "php-$PHP_VERSION.tar.gz.sha1"
	cd "$INSTALL_DIR"
}

# clean up previous work
rm -rf "$INSTALL_DIR"

# setup build directory
if [ ! -d "$BUILD_DIR" ]; then
	mkdir "$BUILD_DIR"
fi

# build and install php
build_php54
build_external_extensions

# Remove unused files
rm "$INSTALL_DIR/php/etc/php-fpm.conf.default"
rm -rf "$INSTALL_DIR/php/include"
rm -rf "$INSTALL_DIR/php/php/man"
rm -rf "$INSTALL_DIR/php/lib/php/build"

# Build binaries - one for PHP, one for FPM and one for each module
package_php_extensions
package_php_fpm
package_php

echo "Done!"

