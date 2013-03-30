#!/bin/bash

test_description="git-silo checkout (missing)"

. ./sharness/sharness.sh

. "$SHARNESS_TEST_DIRECTORY/setup-user.sh"

test_expect_success \
"git-silo checkout should handle missing objects gracefully" \
'
    git init &&
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
    rm a b &&
    ( git-silo checkout . || true ) &&
    test -e b
'

test_done
