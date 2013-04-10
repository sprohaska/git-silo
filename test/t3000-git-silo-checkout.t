#!/bin/bash

test_description="git-silo checkout"

. ./_testinglib.sh

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file a &&
    setup_repo repo1 &&
    setup_add_file repo1 a
'

test_expect_success \
"git status should be clean right after git-silo checkout." \
"
    git clone repo1 repo2 &&
    (
        cd repo2 &&
        git-silo init &&
        git-silo fetch &&
        git-silo checkout a &&
        touch ../empty &&
        git status --porcelain >../actual
    ) &&
    test_cmp empty actual
"

test_done
