#!/bin/bash -e

DIR_THIS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WDIR=monero-patches-build
MONERO_DIR=monero-master
mkdir -p $WDIR && cd $WDIR

if [ -d $MONERO_DIR ]; then
	rm $MONERO_DIR -fr
fi

git clone --recursive https://github.com/monero-project/monero.git $MONERO_DIR
rm $MONERO_DIR/.git -fr # not useful for this test and takes a lot of space
echo "Compressing the master branch..."
tar -czf $MONERO_DIR.tgz $MONERO_DIR

SUCCESSFUL=()
FAILED=()

for patch in $DIR_THIS/src/*.patch; do
	echo $patch
	rm $MONERO_DIR -fr
	tar -xf $MONERO_DIR.tgz
	pushd $MONERO_DIR
		if git apply $patch; then
			SUCCESSFUL+=($patch)
		else
			FAILED+=($patch)
		fi
	popd
done

print_patches() {
	echo ""
	echo "===================="
	echo "Listing $1:"
	echo "===================="
}

print_patches "failed" 
printf '%s\n' "${FAILED[@]}"

print_patches "successful"
printf '%s\n' "${SUCCESSFUL[@]}"
