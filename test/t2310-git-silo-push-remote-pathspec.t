#!/bin/bash

test_description="pathspec to limit push"

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
    cd repo1 &&
    git init &&
    git-silo init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    cd .. &&
    git clone repo1 repo2 &&
    cd repo2 &&
    git-silo init &&
    cp ../a a &&
    git-silo add a &&
    git commit -m "Add a" &&
    cp ../b b &&
    git-silo add b &&
    git commit -m "Add b" &&
    cd ../repo1 &&
    cd ..
'

test_expect_success \
'origin.remote.silopush pathspec should limit git push' \
'
    cd repo2 &&
    git config remote.origin.silopush a &&
    git-silo push &&
    cd ../repo1 &&
    git pull ../repo2 &&
    git-silo checkout a &&
    ! git-silo checkout b
'

test_expect_success \
'"git-silo push -- ." should override origin.remote.silopush' \
'
    cd ../repo2 &&
    git-silo push -- . &&
    cd ../repo1 &&
    git-silo checkout b
'

test_done
