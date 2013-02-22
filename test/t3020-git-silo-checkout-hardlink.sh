#!/bin/bash

test_description="git-silo checkout"

. ./sharness/sharness.sh

linkCount() {
    ls -l $1 | sed -e 's/  */ /' | cut -d ' ' -f 2
}

test_expect_success \
"git checkout should use hardlink if possible." \
'
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git-silo init
    echo a >a &&
    git-silo add a &&
    git commit -m "Add a" &&
    rm a &&
    git-silo checkout a &&
    test $(linkCount a) -eq 2 &&
    ! test -w a
'

test_done
