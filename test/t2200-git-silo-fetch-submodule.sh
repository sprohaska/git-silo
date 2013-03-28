#!/bin/bash

test_description="git-silo dedup"

. ./sharness/sharness.sh

test_expect_success \
"setup user" \
'
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
'

test_expect_success \
"Setup submodule" \
'
    mkdir super &&
    cd super &&
        git init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m "initial commit" &&
        mkdir sub &&
        cd sub &&
            git init &&
            touch .gitignore &&
            git add .gitignore &&
            git commit -m "initial commit" &&
            git-silo init
            echo a >a &&
            git-silo add a &&
            git commit -m "Add a" &&
        cd .. &&
        git submodule add ./sub &&
        git commit -m "add sub" &&
    cd .. &&
    git clone super super2 &&
    cd super2 &&
        git submodule update --init &&
        cd sub &&
            git-silo init &&
            git-silo fetch &&
        cd ..
    cd ..
'

test_expect_success \
"local fetch should correctly handle submodule that uses 'gitdir: ...' redirect." \
'
    git clone super2/sub sublocal &&
    cd sublocal &&
        git-silo init &&
        git-silo fetch &&
        git-silo checkout a &&
        echo a >expected &&
        test_cmp expected a &&
    cd ..
'

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"ssh fetch should correctly handle submodule that uses 'gitdir: ...' redirect." \
'
    git clone "ssh://localhost$(pwd)/super2/sub" subssh &&
    cd subssh &&
        git-silo init &&
        git-silo fetch &&
        git-silo checkout a &&
        echo a >expected &&
        test_cmp expected a &&
    cd ..
'

test_done
