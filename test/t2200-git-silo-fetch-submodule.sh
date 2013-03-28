#!/bin/bash

test_description="git-silo dedup"

. ./sharness/sharness.sh

test_expect_success \
"fetch should correctly fetch from submodule that uses 'gitdir: ...' redirect." \
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
    cd .. &&
    git clone super2/sub sub2 &&
    cd sub2 &&
        git-silo init &&
        git-silo fetch &&
        git-silo checkout a &&
        echo a >expected &&
        test_cmp expected a
'

test_done
