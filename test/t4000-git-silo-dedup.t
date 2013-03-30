#!/bin/bash

test_description="git-silo dedup"

. ./sharness/sharness.sh

linkCount() {
    ls -l $1 | sed -e 's/  */ /' | cut -d ' ' -f 2
}

. "$SHARNESS_TEST_DIRECTORY/setup-user.sh"

test_expect_success \
"git dedup should create hardlinks between two repositories" \
'
    mkdir repo1 &&
    cd repo1 &&
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git-silo init
    echo a >a &&
    git-silo add a &&
    git commit -m "Add a" &&
    cd .. &&
    git clone repo1 repo2 &&
    cd repo2 &&
    git-silo init &&
    git-silo fetch &&
    git-silo checkout . &&
    ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
    git-silo dedup ../repo1 . &&
    rm -r a &&
    git-silo checkout . &&
    ( test $(linkCount a) -eq 4 || ( echo "Wrong link count." && false ) )
'

test_done
