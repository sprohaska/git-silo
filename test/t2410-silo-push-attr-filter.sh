#!/bin/bash

test_description='
Test that "silo push" selects paths based on gitattribute "silo".
'

. ./lib-silo.sh

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
'setup' \
'
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    git clone repo1 repo2 &&
    (
        cd repo2 &&
        git-silo init
    ) &&
    setup_add_file repo2 a &&
    setup_add_file repo2 b &&
    (
        cd repo1 &&
        git pull ../repo2
    )
'

pushWithAttr() {
    local attr="$1"
    shift
    (
        cd repo1 &&
        rm -f b &&
        rm -rf .git/silo/objects &&
        git-silo init
    ) && (
        cd repo2 &&
        git checkout -- .gitattributes &&
        printf "/b silo=%s\n" "${attr}" >>.gitattributes &&
        git-silo push "$@" -- .
    )
}

assertNotPushed() {
    (
        cd repo1 &&
        ! git-silo checkout b
    )
}

assertPushed() {
    (
        cd repo1 &&
        git-silo checkout b
    )
}

test_expect_success \
"attr 'silo=local' should limit git push." \
'
    pushWithAttr "local" && assertNotPushed
'

test_expect_success \
"attr 'silo=a,local' should limit git push." \
'
    pushWithAttr "a,local" && assertNotPushed
'

test_expect_success \
"attr 'silo=local,a' should limit git push." \
'
    pushWithAttr "local,a" && assertNotPushed
'

test_expect_success \
"'git-silo push --verbose' should mention skipped files." \
'
    pushWithAttr "local" --verbose 2>log &&
    grep -q "skipping.*b" log
'

test_expect_success \
"'git-silo push --all' should override 'silo=local'." \
'
    pushWithAttr "local" --all && assertPushed
'

test_done
