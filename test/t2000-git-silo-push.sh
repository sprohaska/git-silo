#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

test_expect_success \
"'git-silo push' should push" \
"
    echo a >a &&
    ( openssl sha1 a | cut -d ' ' -f 2 > a.sha1 ) &&
    mkdir repo1 &&
    cd repo1 &&
    git init &&
    git-silo init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m 'initial commit' &&
    cd .. &&
    git clone 'ssh://localhost$(pwd)/repo1' repo2 &&
    cd repo2 &&
    git-silo init &&
    cp ../a a &&
    git-silo add a &&
    git commit -m 'Add a' &&
    git-silo push &&
    cd .. &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp a.sha1 actual
"

test_done
