#!/bin/bash

test_description="pathspec to limit fetch"

. ./sharness/sharness.sh

. "$SHARNESS_TEST_DIRECTORY/setup-user.sh"

test_expect_success \
'setup' \
'
    echo a >a &&
    ( openssl sha1 a | cut -d " " -f 2 > a.sha1 ) &&
    echo b >b &&
    ( openssl sha1 b | cut -d " " -f 2 > b.sha1 ) &&
    mkdir repo1 &&
    cd repo1 &&
    git init &&
    git-silo init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    cd .. &&
    git clone repo1 repo2 &&
    cd repo1 &&
    cp ../a a &&
    git-silo add a &&
    git commit -m "Add a" &&
    cp ../b b &&
    git-silo add b &&
    git commit -m "Add b" &&
    cd ../repo2 &&
    git-silo init &&
    cd ..
'

test_expect_success \
'origin.remote.silofetch pathspec should limit git fetch' \
'
    cd repo2 &&
    git config remote.origin.silofetch a &&
    git pull &&
    git-silo fetch &&
    git-silo checkout a &&
    ! git-silo checkout b
'

test_expect_success \
'"git-silo fetch -- ." should override origin.remote.silofetch' \
'
    git-silo fetch -- . &&
    git-silo checkout b
'

test_done
