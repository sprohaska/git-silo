#!/bin/bash

test_description="git-silo checkout"

. ./sharness/sharness.sh

test_expect_success \
"setup user" \
'
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
'

test_expect_success \
"git status should be clean right after git-silo checkout." \
"
    mkdir repo1 &&
    cd repo1 &&
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m 'initial commit' &&
    git-silo init
    echo a >a &&
    git-silo add a &&
    git commit -m 'Add a' &&
    cd .. &&
    git clone repo1 repo2 &&
    cd repo2 &&
    git-silo init &&
    git-silo fetch &&
    git-silo checkout a &&
    touch ../empty &&
    git status --porcelain >../actual &&
    cd .. &&
    test_cmp empty actual
"

test_done
