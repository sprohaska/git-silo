#!/bin/bash

test_description="git-silo add (hardlink)"

. ./_testinglib.sh

test_expect_success \
"setup" \
'
    setup_user
'

test_expect_success \
"git add should use hardlink per default" \
'
    setup_repo default &&
    (
        cd default &&
        echo a >a &&
        git-silo add a &&
        ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
        ! test -w a
    )
'

test_expect_success \
"git add should use hardlink when silo.add = link" \
'
    setup_repo link &&
    (
        cd link &&
        git config silo.add link &&
        echo a >a &&
        git-silo add a &&
        ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
        ! test -w a
    )
'

test_expect_success \
"git add should use copy when silo.add = copy" \
'
    setup_repo copy &&
    (
        cd copy &&
        git config silo.add copy &&
        echo a >a &&
        git-silo add a &&
        ( test $(linkCount a) -eq 1 || ( echo "Wrong link count." && false ) ) &&
        test -w a
    )
'

test_expect_success \
"git add should warn about invalid silo.add and use default (link)" \
'
    setup_repo invalid &&
    (
        cd invalid &&
        git config silo.add invalid-option-value &&
        echo a >a &&
        git-silo add a 2>err &&
        grep -q -i warning err &&
        ( test $(linkCount a) -eq 2 || ( echo "Wrong link count." && false ) ) &&
        ! test -w a
    )
'

test_done
