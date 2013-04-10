#!/bin/bash

test_description="git-silo (basic)"

. ./_testinglib.sh

test_expect_success \
"'git-silo init' should succeed." \
"
    git init &&
    git-silo init
"

test_done
