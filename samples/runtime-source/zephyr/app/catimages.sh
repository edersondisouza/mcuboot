#!/bin/bash

PADSIZE=16384

if [ $# -eq 0 ]; then
    echo "Usage: $0 image1 image2"
    exit 1
fi

tmpfile=$(mktemp /tmp/zero.XXXXXX)
pad=$(ls -l $1 | awk -v "PADSIZE=$PADSIZE" '{print PADSIZE-$5}')

dd if=/dev/zero bs=$pad count=1 > $tmpfile

cat $1 $tmpfile $2
