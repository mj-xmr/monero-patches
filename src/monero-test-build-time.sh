#!/bin/bash -e

# Monero build time tester
# Author: mj-xmr

# This script tests build time and addresses the following problems:
# - Eliminates I/O interference, as the build and source directories reside on RAMDisk
# - Reduces linking time, since dynamic linkage is used
# - Uses just 1 thread for timed builds, solving thread starvation problem, as well as RAM depletion during compilation of large files
# - Repeats the whole comparative experiment in a reverse order, to estimate if the RAM caches influence the result depending on the order in which it's being built.
# - TODO: uses ninja to further reduce cmake's I/O bottlenecks.

# Works under Linux and Mac OSX

# Script's arguments:
BRANCH_NAME=$1
TARGET=$2 # Target to be built. Can be set to "all"
# REPO_URL=$3 # Optional: URL to the Monero fork to be tested.


#DIR_SRC=../..
REPO_URL="https://github.com/mj-xmr/monero-mj.git"
LOCAL_COPY_NAME="monero-build-time-test"
DIR_BUILD="build/time"


if [ -z $1 ]; then
	echo "Please provide branch name"
	exit 1
fi

if [ ! -z $3 ]; then
	REPO_URL=$3
fi

# Use RAM disk to rule out I/O bottlenecks 
# (but won't rule out memory bottlenecks, so no XMR mining while testing!)
if [ "$(uname)" == "Linux" ]; then
        DIR_SRC=/dev/shm
        PROC=$(nproc) # Will take less time, but can easily deplete RAM
        #PROC=1
else
	# Creating RAM disk on Mac OSX:
	# https://superuser.com/questions/121989/can-i-put-tmp-and-var-log-in-a-ramdisk-on-os-x/123395#123395
	# https://superuser.com/questions/1480144/creating-a-ram-disk-on-macos
	# https://gist.github.com/htr3n/344f06ba2bb20b1056d7d5570fe7f596
	# https://eshop.macsales.com/blog/46348-how-to-create-and-use-a-ram-disk-with-your-mac-warnings-included/
	RD=ramdisk
	#DIR_SRC="/Volumes/$RD"
	#if [ ! -e "$DIR_SRC" ];  then
	#    diskutil erasevolume HFS+ "$RD" `hdiutil attach -nomount`
	#fi
	# TODO: Disabled Mac RAM disk for now
	DIR_SRC=$(pwd)
	PROC=$(sysctl -n hw.ncpu)
	#PROC=1
fi

do_cmake() {
	git submodule update --init --force
	git submodule update --remote; git submodule sync && git submodule update
	cmake -S "$DIR_SRC/$LOCAL_COPY_NAME" -DUSE_CCACHE=OFF -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS=ON -DSTRIP_TARGETS=ON -DUSE_UNITY=ON 
}


date_utc() {
	date -u
}

free_mem () {
if [ "$(uname)" == "Linux" ]; then
	free -g
else
	sysctl -n hw.memsize
fi	
}

line() {
	echo "+=============================================+"
}

msg() {
	echo ""
	line
	echo "| $1"
	line
}

do_make() {
	
	if [ -z $2 ]; then
		msg "Building ALL of $1"
		cd "$DIR_SRC/$LOCAL_COPY_NAME/$DIR_BUILD"
		make clean && time make > /dev/null 2>&1
		msg "Built ALL of $1 on:"
		date_utc
		free_mem
		line
	else 
		msg "Building target: $2 of $1"
		cd "$DIR_SRC/$LOCAL_COPY_NAME/$DIR_BUILD/$2"
		# Build the deps first and then time only the target itself.
		make -j${PROC} > /dev/null 2>&1 && make clean && time make
		msg "Built target $2 of $1 on:"
		date_utc
		free_mem
		line
	fi
}

checkout_branch() {
	msg "Checking out branch: $1..."
	git checkout $1
	git pull
}

do_branch() {
	do_cmake > /dev/null && make clean && do_make $1 $2
}

do_branch_silent() {
	do_cmake > /dev/null 2>&1 && make clean && do_make $1 $2
}

do_master() {
	checkout_branch master
	do_branch_silent master $1
}



if [ ! -d "$DIR_SRC/$LOCAL_COPY_NAME" ]; then
	cd "$DIR_SRC"
	git clone $REPO_URL "$LOCAL_COPY_NAME"
	cd "$LOCAL_COPY_NAME"
else
	cd "$DIR_SRC/$LOCAL_COPY_NAME"
fi

mkdir -p "$DIR_BUILD" && cd "$DIR_BUILD"

checkout_branch $BRANCH_NAME
do_branch $BRANCH_NAME
do_branch_silent $BRANCH_NAME $TARGET
do_master $TARGET
do_master

echo ""
msg "Repeating the experiment in reverse order to measure caches / RAM bottlenecks influencing the result."
echo ""

do_master
do_master $TARGET
checkout_branch $BRANCH_NAME
do_branch_silent $BRANCH_NAME $TARGET
do_branch_silent $BRANCH_NAME

# Copyright (c) 2022-2023, mj-xmr
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are
# permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this list of
#    conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice, this list
#    of conditions and the following disclaimer in the documentation and/or other
#    materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors may be
#    used to endorse or promote products derived from this software without specific
#    prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
# THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

