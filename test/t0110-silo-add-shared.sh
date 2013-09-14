#!/bin/bash

test_description='
Test that "silo add" maintains shared permissions.
'

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success UNIX \
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
