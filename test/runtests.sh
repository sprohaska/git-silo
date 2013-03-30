#!/bin/bash

cd $(dirname "$0")
for t in t????-*.t; do
    ./$t
done
