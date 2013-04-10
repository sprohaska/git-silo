#!/bin/bash

test_description="git-silo push"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"'git-silo fetch' (scp) should not abort on missing objects." \
'
    echo a >a &&
    ( openssl sha1 a | cut -d " " -f 2 > a.sha1 ) &&
    mkdir repo1 &&
    cd repo1 &&
    git init &&
    git-silo init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git-silo init &&
    echo a >a &&
    ( openssl sha1 a | cut -d " " -f 2 > a.sha1 ) &&
    echo b >b &&
    ( openssl sha1 b | cut -d " " -f 2 > b.sha1 ) &&
    git-silo add a b &&
    git commit -m "Add a b"
    rm -rf .git/silo/objects/$(cut -b 1-2 a.sha1) &&
    cd .. &&
    setup_clone_ssh repo1 repo2 &&
    cd repo2 &&
    git-silo init &&
    ( git-silo fetch || true ) &&
    git-silo checkout b &&
    test -e b
'

test_done
