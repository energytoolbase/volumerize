#!/bin/bash -x

set -o errexit    # abort script at first error

# Setting environment variables
readonly CUR_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
source $CUR_DIR/release.sh
source $CUR_DIR/testImage.sh
printf '%b\n' ":: Testing default image...."
release
testImage $IMAGE_TAG

