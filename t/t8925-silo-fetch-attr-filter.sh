#!/bin/bash

test_description='
Test that "silo fetch" selects path based on gitattribute "silo".
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user
'

test_expect_success 'setup' '
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    setup_add_file repo1 a &&
    setup_add_file repo1 b &&
    git clone repo1 repo2 && (
        cd repo2 &&
        git silo init
    )
'

fetchWithAttr() {
    local attr="$1"
    shift
    (
        cd repo2 &&
        rm -f b &&
        rm -rf .git/silo/objects &&
        git silo init &&
        git checkout -- .gitattributes &&
        printf "/b silo=%s\n" "${attr}" >>.gitattributes &&
        git silo fetch "$@" -- .
    )
}

assertNotFetched() {
    (
        cd repo2 &&
        ! git silo checkout b
    )
}

assertFetched() {
    (
        cd repo2 &&
        git silo checkout b
    )
}

test_expect_success "attr 'silo=local' should limit git fetch." '
    fetchWithAttr "local" &&
    assertNotFetched
'

test_expect_success "attr 'silo=a,local' should limit git fetch." '
    fetchWithAttr "a,local" &&
    assertNotFetched
'

test_expect_success "attr 'silo=local,a' should limit git fetch." '
    fetchWithAttr "local,a" &&
    assertNotFetched
'

test_expect_success "'silo fetch --verbose' should mention skipped files." '
    fetchWithAttr "local" --verbose 2>log &&
    grep -q "skipping.*b" log
'

test_expect_success \
"'silo fetch --all' should override attr 'silo=local'." '
    fetchWithAttr "local" --all &&
    assertFetched
'

test_expect_success \
"'silo fetch --include=a* --exclude=b*' should fetch 'silo=aaa,bbb,local'." '
    fetchWithAttr "aaa,bbb,local" --include=a* --exclude=b* &&
    assertFetched
'

test_expect_success \
"'silo fetch --exclude=b* --include=a*' should not fetch 'silo=aaa,bbb,local'." '
    fetchWithAttr "aaa,bbb,local" --exclude=b* --include=a* &&
    assertNotFetched
'

test_expect_success \
"'silo fetch --exclude=b* --include=a*' should fetch 'silo=aaa,local'." '
    fetchWithAttr "aaa,xxx,local" --exclude=b* --include=a* &&
    assertFetched
'

test_expect_success "'git silo fetch --exclude=a* --all' should fetch." '
    fetchWithAttr "aaa" --exclude=a* --all &&
    assertFetched
'

test_done
