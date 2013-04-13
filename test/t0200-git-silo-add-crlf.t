#!/bin/bash

test_description="git-silo (basic)"

. ./_testinglib.sh

test_expect_success \
"setup" \
'
    setup_user &&
    setup_repo input &&
    setup_repo crlf
'

test_expect_success \
"git-silo add should not use CRLF when core.autocrlf is input." \
'
    (
        cd input &&
        git config core.autocrlf input &&
        touch a &&
        git-silo add a 2>err &&
        ! grep -q warning err
    )
'

test_expect_success \
"git-silo add should use CRLF when core.autocrlf is true." \
'
    (
        cd crlf &&
        git config core.autocrlf true &&
        touch a &&
        git-silo add a 2>err &&
        ! grep -q warning err
    )
'

test_done
