#!/bin/bash

test_description='
Test basic "silo checkout" operations.
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

test_expect_success \
"git checkout should replace placeholder file." \
'
    git clone repo1 repolf &&
    (
        cd repolf &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout a &&
        test_cmp ../a a
    )
'

test_expect_success \
"git checkout should replace placeholder file even when it contains ends with crlf." \
'
    git clone repo1 repocrlf &&
    (
        cd repocrlf &&
        git rm .gitattributes &&
        git commit -m "Remove -text attribute to get CRLF checkout."
        git config core.autocrlf true &&
        rm a &&
        git checkout a &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout a &&
        test_cmp ../a a
    )
'

test_expect_success \
"git status should be clean right after git-silo checkout." \
"
    git clone repo1 repo2 &&
    (
        cd repo2 &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout a &&
        touch ../empty &&
        git status --porcelain >../actual
    ) &&
    test_cmp empty actual
"

test_done
