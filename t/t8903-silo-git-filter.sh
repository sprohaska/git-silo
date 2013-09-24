#!/bin/bash

test_description='
Test that git filters to handle silo content work as expected.
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user &&
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    setup_add_file repo1 a
'

test_expect_success "git should receive correct silo content" '
    (
        cd repo1 &&
        rm a &&
        git checkout HEAD -- a
    ) &&
    test_cmp a repo1/a
'

test_expect_success \
"git repo should continue functioning when git silo executable is removed" '
    rm -f git-silo &&
    cp "$(locate_git_silo)" ./git-silo &&
    export PATH=$(pwd):$PATH &&
    setup_repo repomv &&
    rm git-silo &&
    setup_add_file repomv a 2>err &&
    ! grep -q "error: external filter" err &&
    ( cd repomv && git show HEAD:a ) | egrep -q "^[0-9a-f]{40}"
'

test_expect_success "git repo should continue functioning when it is moved" '
    mv repomv repomv2 &&
    setup_add_file repomv2 b 2>err &&
    ! grep -q "error: external filter" err &&
    ( cd repomv2 && git show HEAD:b ) | egrep -q "^[0-9a-f]{40}"
'

test_done
