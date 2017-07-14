#!/usr/bin/env bash

set -x

date

PREREQ_FAILED="0"
ensure() {
    echo -ne "checking for ${1}... "
    if hash $1 2>/dev/null; then
        echo "FOUND"
    else
        PREREQ_FAILED="1"
        echo "NOT FOUND"
    fi
}

ensure curl
ensure sdc-imgadm
ensure vmadm # depended on by scripts in image-converter submodule

if [ "$PREREQ_FAILED" == "1" ]; then
    echo >&2 "Prerequisite check failed. Aborting"; exit 1;
fi

VERSION=2.18
IMAGE_NAME="zenhub-enterprise-${GITHUB_VERSION}"
IMAGE_FILENAME="zenhub-enterprise-vmware-11-${VERSION}.ova"
DOWNLOAD_URI="https://s3.amazonaws.com/zenhub/enterprise/enterprise-builds/${VERSION}/11/${IMAGE_FILENAME}.ova"
echo "Downloading image..."; date

curl --insecure --retry 2 -O $DOWNLOAD_URI

echo "Converting image..."; date

pushd image-converter
./convert-image -i "../${IMAGE_FILENAME}" -n $IMAGE_NAME -o linux

# TODO: It might be nice to improve image-converter to take a
# desitination path here

mv *.json ..
mv *.gz ..

popd

echo "Importing image..."; date

sdc-imgadm import -m ./${MANIFEST} -f ./${IMAGE_FILENAME}

echo "Finished!"; date
