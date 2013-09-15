#!/bin/bash

test_description='
Test interaction with "core.autocrlf".
'

. ./lib-silo.sh

test_expect_success \
"setup" \
'
    setup_user &&
    setup_repo input &&
    setup_repo crlf
'

test_expect_success \
"git silo add should not use CRLF for core.autocrlf=input." \
'
    (
        cd input &&
        git config core.autocrlf input &&
        touch a &&
        git silo add a 2>err &&
        ! grep -q warning err
    )
'

test_expect_success \
"git silo add should use CRLF for core.autocrlf=true." \
'
    (
        cd crlf &&
        git config core.autocrlf true &&
        touch a &&
        git silo add a 2>err &&
        ! grep -q warning err
    )
'

test_done
