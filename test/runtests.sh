#!/bin/bash

cd $(dirname "$0")
for t in t????-*.t; do
    echo
    echo "# $t"
    ./$t
done
