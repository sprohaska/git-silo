#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

test_expect_success \
"'git-silo init' should succeed." \
"
    git init &&
    git-silo init
"

test_done
