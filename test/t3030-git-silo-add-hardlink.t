#!/bin/bash

test_description="git-silo add (hardlink)"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"git add should use hardlink" \
'
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git-silo init
    echo a >a &&
    git-silo add a &&
    ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
    ! test -w a
'

test_done
