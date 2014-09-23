#!/bin/bash

test_description='
Test automatic unpack
'

. ./lib-silo.sh

if ! type 7zr >/dev/null 2>&1; then
    skip_all='Skipping tests, because 7zr is not available.'
    test_done
fi

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
