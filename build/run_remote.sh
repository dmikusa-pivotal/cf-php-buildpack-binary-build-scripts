#!/bin/bash
#
# Connect to a remote machine, build there and download output.
#
#  - remote environment needs to be setup and listening for SSH
#  - remote environment needs git installed
#  - process will install dependencies on the remote environment
#
# Date: 6-9-2014
# Author: Daniel Mikusa <dmikusa@gopivotal.com>
#
# Usage:
#   ./run_remote.sh [user@]hostname
#
set -e

REMOTE_HOST=$1
if [ "$REMOTE_HOST" == "" ]; then
    echo "Usage:"
    echo "  run_remote.sh <host/ip>"
    exit -1
fi

# Get ROOT Directory
if [[ "$0" == /* ]]; then
    ROOT=$(dirname "$(dirname "$0")")
else
    ROOT=$(dirname $(dirname "$(pwd)/${0#./}"))
fi

function remote_test {
    ssh -q "$REMOTE_HOST" "$1"
    return $?
}

function remote_run {
    ssh -qt "$REMOTE_HOST" "$1"
    return $?
}

function remote_capture {
    CAPTURE=$(ssh -qt "$REMOTE_HOST" "$1")  # Returning "Ubuntu\n", not sure why
    return $?
}

# TODO: Install ssh key into access file?

# Install git
# TODO: move into common file (used by both remote_* scripts)
if ! remote_test "hash git 2\>/dev/null"; then
    echo "Git not installed on the remote host.  Attempting to install..."
    remote_capture "cat /etc/issue | cut -d ' ' -f 1 | tr -d '\n'"
    if [ "$CAPTURE" == "Ubuntu" ]; then
        remote_run "sudo apt-get -y install git-core"
    elif [ "$CAPTURE" == "CentOS" ]; then 
        remote_run "sudo yum install git"
    else
        echo "Not sure about the remote OS, please manually install git."
        exit -1
    fi
fi

# Clone or update the repo
if remote_test "[ -d cf-php-buildpack-binary-build-scripts ]"; then 
    remote_run "cd cf-php-buildpack-binary-build-scripts; git pull"
else
    remote_run "git clone https://github.com/dmikusa-pivotal/cf-php-buildpack-binary-build-scripts.git"
fi

# Update / install dependencies
remote_run "cd cf-php-buildpack-binary-build-scripts; ./build/install-deps.sh"

# Run the build-all.sh script
remote_run "cd cf-php-buildpack-binary-build-scripts; ./build/build-all.sh"

# Copy the binaries to the 
scp -r "$REMOTE_HOST:./cf-php-buildpack-binary-build-scripts/output" "$ROOT"
