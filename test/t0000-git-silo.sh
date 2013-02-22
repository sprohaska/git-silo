#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

test_expect_success "git-silo init will succeed" "
    git init &&
    git-silo init
"

test_done
