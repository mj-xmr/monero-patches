#!/bin/bash -e

#DIR_SRC=../..
REPO_URL="https://github.com/mj-xmr/monero-mj.git"
LOCAL_COPY_NAME="monero-build-time-test"

# Script arguments:
BRANCH_NAME=$1
TARGET=$2 # can be set to "all"

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
	DIR_SRC="/Volumes/$RD"
	if [ ! -e "$DIR_SRC" ];  then
	    diskutil erasevolume HFS+ "$RD" `hdiutil attach -nomount`
	fi

	PROC=$(sysctl -n hw.ncpu)
	#PROC=1
fi

do_cmake() {
	git submodule update --init --force
	git submodule update --remote; git submodule sync && git submodule update
	cmake -S "$DIR_SRC/$LOCAL_COPY_NAME" -DUSE_CCACHE=ON -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS=ON -DSTRIP_TARGETS=ON -DUSE_UNITY=ON 
}

line() {
	echo "+===============================================================+"
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
		make clean && time make > /dev/null 2>&1
		msg "Built ALL of $1 on:"
		date
		line
	else 
		msg "Building target: $2 of $1"
		make -j${PROC} > /dev/null 2>&1 && cd "$2" && make clean && time make
		msg "Built target $2 of $1 on:"
		date
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

mkdir -p build/time && cd build/time

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

