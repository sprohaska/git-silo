#!/bin/bash

test_description="git-silo dedup"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"git dedup should create hardlinks between two repositories" \
'
    setup_file a &&
    setup_repo repo1 &&
    setup_add_file repo1 a &&
    git clone repo1 repo2 &&
    (
        cd repo2 &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout . &&
        ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
        git-silo dedup ../repo1 . &&
        rm -r a &&
        git-silo checkout . &&
        ( test $(linkCount a) -eq 4 || ( echo "Wrong link count." && false ) )
    )
'

test_done
