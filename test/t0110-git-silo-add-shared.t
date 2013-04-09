#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

. "$SHARNESS_TEST_DIRECTORY/setup-user.sh"

isSharedDir() {
    test -g "$1"
}

test_expect_success \
"'git-silo add' should create subdir with shared permissions in shared repo." \
'
    git init --shared &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git-silo init &&
    echo a >"a a" &&
    git-silo add "a a" &&
    isSharedDir .git/silo/objects/*
'

test_done
