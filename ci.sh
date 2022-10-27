#!/bin/bash -e

DIR_THIS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WDIR=/tmp/monero/monero-patches-build
LOG=log.txt
PROC=$(nproc)

BUILD=false
if [ ! -z $1 ]; then
	BUILD=true
	echo "Installing 'monero' dependencies..."
	sudo apt install build-essential cmake pkg-config libssl-dev libzmq3-dev libunbound-dev libsodium-dev libunwind8-dev liblzma-dev libreadline6-dev libexpat1-dev libpgm-dev libhidapi-dev libusb-1.0-0-dev libprotobuf-dev protobuf-compiler libudev-dev libboost-chrono-dev libboost-date-time-dev libboost-filesystem-dev libboost-locale-dev libboost-program-options-dev libboost-regex-dev libboost-serialization-dev libboost-system-dev libboost-thread-dev python3 ccache
fi

mkdir -p $WDIR && cd $WDIR

ALL_VERS="release-v0.17 release-v0.18 master"
for VERSION in $ALL_VERS; do
	echo $VERSION
	ARCHIVE=$VERSION.tgz
	if [ -d $VERSION ]; then
		echo "Removing $VERSION"
		rm $VERSION -fr
	fi
	if [ ! -f $ARCHIVE ]; then
		git clone --recursive https://github.com/monero-project/monero.git $VERSION
		pushd $VERSION
			#git checkout $(git branch -a | grep $VERSION | tail -1) # Automates latest release detection
			git checkout $VERSION
		popd
		rm $VERSION/.git -fr # not useful for this test and takes a lot of space
		echo "Compressing the $VERSION branch..."
		tar -czf $ARCHIVE $VERSION
	fi
	ls -lh $ARCHIVE
done


print_patches() {
	echo "" | tee -a $LOG_FILE
	echo "====================" | tee -a $LOG_FILE
	echo "Listing $1:" | tee -a $LOG_FILE
	echo "====================" | tee -a $LOG_FILE
}

report() {
	DIR="$DIR_THIS/out"
	mkdir -p $DIR
	LOG_FILE=$DIR/$1-$LOG
	echo "" > $LOG_FILE
	print_patches "failed" $LOG_FILE 
	printf '%s\n' "${FAILED[@]}" | tee -a $LOG_FILE

	print_patches "successful" $LOG_FILE
	printf '%s\n' "${SUCCESSFUL[@]}" | tee -a $LOG_FILE
	
	print_patches "failed build" $LOG_FILE
	printf '%s\n' "${FAILED_BUILD[@]}" | tee -a $LOG_FILE
}


for VERSION in $ALL_VERS; do
	SUCCESSFUL=()
	FAILED=()
	FAILED_BUILD=()
	for patch in $DIR_THIS/src/*.patch; do
		rm $VERSION -fr
		tar -xf $VERSION.tgz
		pushd $VERSION
			echo "Trying to apply: $patch"
			if git apply $patch; then
				SUCCESSFUL+=($patch)
				if [ "$BUILD" == "true" ]; then
					mkdir -p build
					pushd build
					if ! (cmake ../ -DCMAKE_BUILD_TYPE=Release -DSTRIP_TARGETS=ON -DBUILD_SHARED_LIBS=ON -DBUILD_TESTS=ON && make -j$PROC); then
						FAILED_BUILD+=($patch)
					fi
					popd
				fi
				
			else
				FAILED+=($patch)
			fi
		popd
	done
	report $VERSION
done

 
