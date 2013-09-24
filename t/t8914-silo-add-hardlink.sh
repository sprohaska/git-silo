#!/bin/bash

test_description='
Test that "silo add" uses hard links as expected.
'

. ./lib-silo.sh

test_expect_success "setup" '
    setup_user
'

assertLinkCount() {
    local file=$1
    local expected=$2
    local actual=$(linkCount "$1")
    [ $actual -eq $expected ] && return 0
    error "Wrong link count, expected ${expected}, actual ${actual}."
}

test_expect_success "git add should use hard link per default" '
    setup_repo default && (
        cd default &&
        echo a >a &&
        git silo add a &&
        assertLinkCount a 2 &&
        ! test -w a
    )
'

test_expect_success "git add should use hard link when silo.add=link" '
    setup_repo link && (
        cd link &&
        git config silo.add link &&
        echo a >a &&
        git silo add a &&
        assertLinkCount a 2 &&
        ! test -w a
    )
'

test_expect_success "git add should use copy when silo.add=copy" '
    setup_repo copy && (
        cd copy &&
        git config silo.add copy &&
        echo a >a &&
        git silo add a &&
        assertLinkCount a 1 &&
        test -w a
    )
'

test_expect_success \
"git add should warn about invalid silo.add and use default (link)" '
    setup_repo invalid && (
        cd invalid &&
        git config silo.add invalid-option-value &&
        echo a >a &&
        git silo add a 2>err &&
        grep -q -i warning err &&
        assertLinkCount a 2 &&
        ! test -w a
    )
'

test_done
