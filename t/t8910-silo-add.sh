#!/bin/bash

test_description='
Test basic "silo add" operations.
'

. ./lib-silo.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"'git silo add' should handle paths with spaces." \
'
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git silo init &&
    echo a >"a a" &&
    git silo add "a a" &&
    git commit -m "Add a a" &&
    ( test $(blobSize "a a") -eq 41 || ( echo "Wrong blob size." && false ) )
'

test_expect_success \
"'git checkout' of silo content should handle paths with spaces." \
'
    rm "a a" &&
    git checkout "a a" &&
    test -e "a a"
'

test_expect_success \
"'git silo checkout' should handle paths with spaces." \
'
    rm "a a" &&
    git silo checkout "a a" &&
    test -e "a a"
'

test_done
