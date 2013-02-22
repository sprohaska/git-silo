#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

test_expect_success \
"'git-silo add' should handle paths with spaces." \
'
    git init &&
    git-silo init &&
    touch "a a" &&
    git-silo add "a a"
'

test_done
