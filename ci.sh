#!/bin/bash -e

DIR_THIS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WDIR=/tmp/monero/monero-patches-build
LOG=log.txt

mkdir -p $WDIR && cd $WDIR

ALL_VERS="release-v0.17 release-v0.18 master"
for VERSION in $ALL_VERS; do
	echo $VERSION
	if [ -d $VERSION ]; then
		echo "Removing $VERSION"
		rm $VERSION -fr
	fi
	git clone --recursive https://github.com/monero-project/monero.git $VERSION
	pushd $VERSION 
		#git checkout $(git branch -a | grep $VERSION | tail -1) # Automates latest release detection
		git checkout $VERSION
	popd
	rm $VERSION/.git -fr # not useful for this test and takes a lot of space
	echo "Compressing the $VERSION branch..."
	tar -czf $VERSION.tgz $VERSION
	ls -lh $VERSION.tgz
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
}


for VERSION in $ALL_VERS; do
	SUCCESSFUL=()
	FAILED=()
	for patch in $DIR_THIS/src/*.patch; do
		rm $VERSION -fr
		tar -xf $VERSION.tgz
		pushd $VERSION
			echo "Trying to apply: $patch"
			if git apply $patch; then
				SUCCESSFUL+=($patch)
			else
				FAILED+=($patch)
			fi
		popd
	done
	report $VERSION
done

 
