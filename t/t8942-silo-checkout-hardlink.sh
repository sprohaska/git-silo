#!/bin/bash

test_description='
Test that "silo checkout" uses hard links as expected.
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user
'

test_expect_success "git checkout should use hard links." '
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git silo init
    echo a >a &&
    git silo add a &&
    git commit -m "Add a" &&
    rm a &&
    git silo checkout a &&
    test $(linkCount a) -eq 2 &&
    ! test -w a
'

test_expect_success "git checkout --copy should not use hard links." '
    git silo checkout --copy a &&
    test $(linkCount a) -eq 1 &&
    test -w a
'

test_expect_success "git checkout --link should replace copy with hard links." '
    git silo checkout --link a &&
    test $(linkCount a) -eq 2 &&
    ! test -w a
'

test_expect_success "git checkout --link should link to object store." '
    git silo checkout --copy a &&
    ln a a2nd &&
    test $(linkCount a2nd) -eq 2 &&
    git silo checkout --link a &&
    test $(linkCount a2nd) -eq 1 &&
    ! test -w a
'

test_expect_success \
"git checkout --link should fix wrong write permissions in silo store." '
    chmod u+w .git/silo/objects/*/* &&
    test -w a &&
    rm a &&
    git silo checkout --link a &&
    ! test -w a
'

test_expect_success \
"git checkout should not use hardlink if xbit mismatch." '
    chmod u+x .git/silo/objects/*/* &&
    rm a &&
    git silo checkout a &&
    ! test -x a &&
    test $(linkCount a) -eq 1
'

test_done
