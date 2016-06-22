#! /bin/bash

mkdir -p $1
for n in $(seq 1 $2); do
    dd if=/dev/urandom of=$1/file$( printf %03d "$n" ).bin bs=1 count=$(( RANDOM + 1024 ))
done
