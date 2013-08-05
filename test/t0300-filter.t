#!/bin/bash

test_description="git-silo (basic)"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user &&
    setup_file a &&
    setup_repo repo1 &&
    setup_add_file repo1 a
'

test_expect_success \
"git should receive correct silo content" \
'
    cd repo1 &&
    rm a &&
    git checkout HEAD -- a &&
    test_cmp ../a a
'

test_done
