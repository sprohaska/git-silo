#!/bin/bash

test_description='
Test that "silo fetch" maintains shared permissions.
'

. ./_testinglib.sh

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file a &&
    setup_repo repo1 &&
    setup_add_file repo1 a
'

test_expect_success UNIX \
"local fetch to shared repo should create subdir with shared permission" \
'
    mkdir repo2 &&
    cd repo2 &&
    git init --shared &&
    git remote add origin ../repo1 &&
    git-silo init &&
    git pull origin master &&
    git-silo fetch -- . &&
    isSharedDir .git/silo/objects/$(cut -b 1-2 ../a.sha1)
'

test_done
