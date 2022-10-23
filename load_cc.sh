#!/usr/bin/env bash

# Change dir
cd /ci

# Use aria2 for cc
down () {
SECONDS=0
time aria2c $1 -x16 -s50
}

# Download cc
echo "• Downloading CCACHE •"
down https://space.orkunergun.workers.dev/ccache/crdroidandroid/ccache.tar.gz || down https://space.orkunergun.workers.dev/ccache/crdroidandroid/ccache.tar.gz

# Extract ccache so ci can use it
echo "• Extracting CCACHE •"
if [ -e *.tar.gz ]; then
time tar xf *.tar.gz
fi

# Remove unnecessary downloaded file
rm -rf *.tar.gz
