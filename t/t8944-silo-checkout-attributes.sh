#!/bin/bash

test_description='
Test "silo checkout" with missing attributes.
'

. ./lib-silo.sh

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_repo repo &&
    setup_add_file repo first
'

# 'git mv' moves the sha1 but does not update the attributes.
test_expect_success "move file without silo" '(
    cd repo &&
    git config core.autocrlf false &&
    git mv first second &&
    git commit -m "move file" &&
    rm second &&
    git reset --hard
)'

test_expect_success "silo checkout should warn and use sha1 placeholder" '(
    cd repo &&
    git silo checkout second 2>../err
) &&
    grep -i -q warn err &&
    test_cmp first.sha1 repo/second
'

test_done
