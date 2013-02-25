#!/bin/bash

cd $(dirname "$0")
for t in t????-*.sh; do
    ./$t
done
