#!/bin/bash -x

set -o errexit    # abort script at first error

function buildImage() {
  local tagname=$1
  local path=${2:-"."}
  shift 2
  docker build --no-cache -t 976401372843.dkr.ecr.us-west-2.amazonaws.com/etb/acumen-backup:$tagname $@ $path
}
