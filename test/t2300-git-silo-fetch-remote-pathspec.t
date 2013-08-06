#!/bin/bash

test_description="pathspec to limit fetch"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
'setup' \
'
    echo a >a &&
    ( openssl sha1 a | cut -d " " -f 2 > a.sha1 ) &&
    echo b >b &&
    ( openssl sha1 b | cut -d " " -f 2 > b.sha1 ) &&
    mkdir repo1 &&
    (
        cd repo1 &&
        git init &&
        git-silo init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m "initial commit"
    ) &&
    git clone repo1 repo2 &&
    (
        cd repo1 &&
        cp ../a a &&
        git-silo add a &&
        git commit -m "Add a" &&
        cp ../b b &&
        git-silo add b &&
        git commit -m "Add b"
    ) &&
    (
        cd repo2 &&
        git-silo init
    )
'

test_expect_success \
'remote.origin.silofetch pathspec should limit git fetch' \
'
    (
        cd repo2 &&
        git config remote.origin.silofetch a &&
        git pull &&
        git-silo fetch &&
        git-silo checkout a &&
        ! git-silo checkout b
    )
'

test_expect_success \
'"git-silo fetch -- ." should override remote.origin.silofetch' \
'
    (
        cd repo2 &&
        git-silo fetch -- . &&
        git-silo checkout b
    )
'

test_done
