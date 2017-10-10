#!/usr/bin/env bash

set -x

START_DATE=`date -u +"%Y%m%dT%H%M%SZ"`
PWD=`pwd`
log() {
    NOW=`date -u +"%Y%m%dT%H%M%SZ"`
    MSG="${NOW} ${1}"
    echo $MSG >> ${PWD}/remote-${START_DATE}.log
    if [ ! $2 == "no" ]; then
        echo $MSG
    fi
}

PREREQ_FAILED="0"
ensure() {
    PREFIX="checking for ${1}..."
    if hash $1 2>/dev/null; then
        log "${PREFIX} FOUND"
    else
        PREREQ_FAILED="1"
        log "${PREFIX} NOT FOUND"
    fi
}

# grab root's profile to pick up path; needed to locate sdc-imgadm
source /root/.bash_profile

ensure sdc-imgadm
ensure vmadm # depended on by scripts in image-converter submodule

if [ "$PREREQ_FAILED" == "1" ]; then
    log "Prerequisite check failed. Aborting" no;
    echo >&2 "Prerequisite check failed. Aborting"; exit 1;
fi

pushd ${SOURCE_IMAGE_DIR}
SOURCE_IMAGE_FILENAME=`ls -1 | grep vmdk | head -n 1`

log "Converting source image ${SOURCE_IMAGE_FILENAME} to ${IMAGE_NAME}..."

pushd image-converter

# remove any existing manifests and converted images
rm -f ./*.json
rm -f ./*.gz

./convert-image -i "../${SOURCE_IMAGE_FILENAME}" -n $IMAGE_NAME -o linux

MANIFEST_FILENAME=`ls -1 *.json | head -n 1`
IMAGE_FILENAME=`ls -1 *.gz | head -n 1`

# TODO: It might be nice to improve image-converter to take a
# desitination path here

mv ./*.json ..
mv ./*.gz ..

popd

# sdc-imgadm import -m ./github-enterprise-2.10.2-2017071022.json -f ./github-enterprise-2.10.2-2017071022.zfs.gz

read -n 1 -s -r -p "Press any key to import image"

log "Importing image ${IMAGE_FILENAME} with manifest ${MANIFEST_FILENAME}"

sdc-imgadm import -m ./${MANIFEST_FILENAME} -f ./${IMAGE_FILENAME}

log "Finished!"