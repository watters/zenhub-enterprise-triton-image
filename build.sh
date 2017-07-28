#!/usr/bin/env bash

set -x

##########################

VERSION=2.20
IMAGE_NAME="zenhub-enterprise-${VERSION}"
IMAGE_FILENAME_BASE="zenhub-enterprise-vmware-11-${VERSION}"
DOWNLOAD_IMAGE_FILENAME="${IMAGE_FILENAME_BASE}.ova"
DOWNLOAD_URI="https://s3.amazonaws.com/zenhub/enterprise/enterprise-builds/${VERSION}/11/${DOWNLOAD_IMAGE_FILENAME}"
BUILD_HOST="sandbox"

##########################

START_DATE=`date -u +"%Y%m%dT%H%M%SZ"`
PWD=`pwd`
log() {
    NOW=`date -u +"%Y%m%dT%H%M%SZ"`
    MSG="${NOW} ${1}"
    echo $MSG >> ${PWD}/build-${START_DATE}.log
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

ensure curl

# ovftool must be downloaded from VMWare https://www.vmware.com/support/developer/ovf/
ensure ovftool

if [ "$PREREQ_FAILED" == "1" ]; then
    log "Prerequisite check failed. Aborting" no;
    echo >&2 "Prerequisite check failed. Aborting"; exit 1;
fi

log "Downloading image ${DOWNLOAD_URI}..."

curl --insecure --retry 2 -O $DOWNLOAD_URI

log "Unpacking OVA ${DOWNLOAD_IMAGE_FILENAME}…"

# use ovftool to extract the ova contents into a directory
ovftool -tt=vmx $DOWNLOAD_IMAGE_FILENAME .

log "Uploading OVA components to image build machine ${BUILD_HOST}…"

# probably a better way to discover the directory that ovftool created
# in a cross-platform way; optimized for linux version of ovftool
# for now

scp -r "${IMAGE_FILENAME_BASE}" root@${BUILD_HOST}:/var/tmp/
scp -r 'image-converter' root@${BUILD_HOST}:/var/tmp/${IMAGE_FILENAME_BASE}/

read -n 1 -s -r -p "Press any key to convert image"

ssh root@${BUILD_HOST} \
SOURCE_IMAGE_DIR="/var/tmp/${IMAGE_FILENAME_BASE}" \
IMAGE_NAME="${IMAGE_NAME}" \
'bash -s' < remote.sh