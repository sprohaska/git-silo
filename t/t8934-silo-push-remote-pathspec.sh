#!/bin/bash

test_description='
Test that "silo push" supports config "remote.*.silopush".
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user
'

test_expect_success 'setup' '
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    git clone repo1 repo2 && (
        cd repo2 &&
        git silo init &&
        cp ../a a &&
        git silo add a &&
        git commit -m "Add a" &&
        cp ../b b &&
        git silo add b &&
        git commit -m "Add b"
    )
'

test_expect_success 'remote.origin.silopush pathspec should limit git push' '
    (
        cd repo2 &&
        git config remote.origin.silopush a &&
        git silo push
    ) && (
        cd repo1 &&
        git pull ../repo2 &&
        git silo checkout a &&
        ! git silo checkout b
    )
'

test_expect_success \
'"git silo push -- ." should override remote.origin.silopush' '
    (
        cd repo2 &&
        git silo push -- .
    ) && (
        cd repo1 &&
        git silo checkout b
    )
'

test_expect_success 'remote.<remote>.silopush pathspec should limit git push' '
    git clone repo1 namedremote && (
        cd namedremote &&
        git silo init &&
        echo "c" >c &&
        git silo add c &&
        git commit -m "Add c" &&
        git remote rename origin org &&
        git config remote.org.silopush a &&
        git silo push org
    ) && (
        cd repo1 &&
        git pull ../namedremote &&
        ! git silo checkout c
    )
'

test_done
