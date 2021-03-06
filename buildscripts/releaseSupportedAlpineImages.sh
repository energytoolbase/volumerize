#!/bin/bash -x

set -o errexit    # abort script at first error

function pushImage() {
  local tagname=$1
  local repository=$2

  docker push fekide/volumerize:$tagname
}

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
readonly PUSH_REPOSITORY=$1
source $CUR_DIR/release.sh

printf '%b\n' ":: Release default image...."
release
pushImage $IMAGE_TAG $PUSH_REPOSITORY


export IMAGE_TYPE=mongodb
printf '%b\n' ":: Release ${IMAGE_TYPE} image...."
release
pushImage $IMAGE_TAG $PUSH_REPOSITORY


export IMAGE_TYPE=mysql
printf '%b\n' ":: Release ${IMAGE_TYPE} image...."
release
pushImage $IMAGE_TAG $PUSH_REPOSITORY


export IMAGE_TYPE=postgres
printf '%b\n' ":: Release ${IMAGE_TYPE} image...."
release
pushImage $IMAGE_TAG $PUSH_REPOSITORY
