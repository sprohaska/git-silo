#!/bin/bash

test_description='
Test that "silo fetch" correctly handles submodules that use a ".git" file to
redirect to the real repository location.
'

. ./lib-silo.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"Setup submodule" \
'
    mkdir super &&
    (
        cd super &&
        git init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m "initial commit" &&
        mkdir sub &&
        (
            cd sub &&
            git init &&
            touch .gitignore &&
            git add .gitignore &&
            git commit -m "initial commit" &&
            git-silo init
            echo a >a &&
            git-silo add a &&
            git commit -m "Add a"
        ) &&
        git submodule add ./sub &&
        git commit -m "add sub"
    ) &&
    git clone super super2 &&
    (
        cd super2 &&
        git submodule update --init &&
        (
            cd sub &&
            git-silo init &&
            git-silo fetch -- .
        )
    )
'

test_expect_success \
"local fetch should correctly handle submodule that uses 'gitdir: ...' redirect." \
'
    git clone super2/sub sublocal &&
    (
        cd sublocal &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout a &&
        echo a >expected &&
        test_cmp expected a
    )
'

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"ssh fetch should correctly handle submodule that uses 'gitdir: ...' redirect." \
'
    setup_clone_ssh super2/sub subssh &&
    (
        cd subssh &&
        git-silo init &&
        git-silo fetch -- . &&
        git-silo checkout a &&
        echo a >expected &&
        test_cmp expected a
    )
'

test_done
