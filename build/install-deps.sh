#!/bin/bash
#
# Install dependencies for building the build pack binaries.
#  This script is for Ubuntu 12.04.  See other branches for
#  support for other OS/Versions.
#
#  Usage:
#    ./install-deps.sh
#
#  Date: 6-9-2014
#  Author:  Daniel Mikusa <dmikusa@gopivotal.com
#
OS=$(cat /etc/issue | cut -d ' ' -f 1)
VERSION=$(cat /etc/issue | cut -d ' ' -f 2)

if [ "$OS" == "Ubuntu" ]; then
	# update repo and packages
	sudo apt-get update
	sudo apt-get -y upgrade
	if [[ "$VERSION" == "12.04"* ]]; then
		sudo apt-get -y install build-essential autoconf automake libssl-dev libsnmp-dev mercurial libbz2-dev libldap2-dev libpcre3-dev libxml2-dev libpq-dev libzip-dev libcurl4-openssl-dev libgdbm-dev libmysqlclient-dev libgmp3-dev libjpeg-dev libpng12-dev libc-client2007e-dev libsasl2-dev libmcrypt-dev libaspell-dev libpspell-dev libexpat1-dev imagemagick libmagickwand-dev libmagickcore-dev unzip libicu-dev
        # Ubuntu 12.04 has some libraries and heads in locations that are not found by configure
        sudo ln -fs /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so
        sudo ln -fs /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap_r.so
	else
		echo "Version [$VERSION] of [$OS] is not supported by this version of the script."
        echo "Check out the appropriate build branch for your version."
		exit -1
	fi
else
    echo "Version [$VERSION] of [$OS] is not supported by this version of the script."
    echo "Check out the appropriate build branch for your version."
	exit -1
fi