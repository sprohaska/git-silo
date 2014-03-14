#!/bin/bash

test_description='
Test automatic unpack
'

. ./lib-silo.sh

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_repo repo &&
    setup_add_file repo first
'

test_expect_success "setup (prune)" '(
    cd repo &&
    git silo pack --prune --all &&
    git config silo.autounpack true
)'

test_expect_success "checkout should autounpack" '(
    cd repo &&
    rm -f first &&
    git silo checkout first
)'

test_done
