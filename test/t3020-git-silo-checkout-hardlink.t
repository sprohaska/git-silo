#!/bin/bash

test_description="git-silo checkout"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"git checkout should use hardlink." \
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

test_expect_success \
"git checkout --copy should not use hardlink." \
'
    git-silo checkout --copy a &&
    test $(linkCount a) -eq 1 &&
    test -w a
'

test_expect_success \
"git checkout --link should replace copy with hardlink." \
'
    git-silo checkout --link a &&
    test $(linkCount a) -eq 2 &&
    ! test -w a
'

test_done
