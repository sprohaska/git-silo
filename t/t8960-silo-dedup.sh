#!/bin/bash

test_description='
Test deduplication.
'

. ./lib-silo.sh

assertLinkCount() {
    local path=$1
    local expected=$2
    if ! test $(linkCount "$path") -eq $expected; then
        echo "Wrong link count $path (expected: $expected; actual: $(linkCount "$path"))."
        return 1
    fi
}

test_expect_success "setup user" '
    setup_user
'

test_expect_success "'git silo dedup' should succeed with empty silos." '
    setup_repo empty1 &&
    setup_repo empty2 &&
    git silo dedup empty1 empty2
'

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

# setup_clone_ssh is used to create repo2 in order to avoid local copy, which
# would immediately create hard links.
test_expect_success LOCALHOST \
"git dedup should create hardlinks between two repositories in expected order" '
    setup_file a &&
    setup_repo repo1 &&
    setup_add_file repo1 a &&
    setup_clone_ssh repo1 repo2 && (
        cd repo2 &&
        git silo init &&
        git silo fetch -- . &&
        git silo checkout .
    ) &&
    assertLinkCount repo1/a 2 &&
    assertLinkCount repo2/a 2 &&
    git silo dedup repo2 repo1 &&
    assertLinkCount repo1/a 1 &&
    assertLinkCount repo2/a 3 && (
        cd repo1 &&
        rm -r a &&
        git silo checkout .
    ) &&
    assertLinkCount repo2/a 4
'

test_expect_success UNIX "'dedup' should not link if x-bit differs" '
    setup_repo repo3 && (
        cd repo3 &&
        echo b >b &&
        chmod u+x b &&
        echo c >c &&
        git silo add -- b c &&
        git commit -m "add b c"
    ) &&
    setup_repo repo4 && (
        cd repo4 &&
        echo b >b &&
        echo c >c &&
        chmod u+x c &&
        git silo add -- b c &&
        git commit -m "add b c"
    ) &&
    assertLinkCount repo3/b 2 &&
    assertLinkCount repo4/b 2 &&
    assertLinkCount repo3/c 2 &&
    assertLinkCount repo4/c 2 &&
    git silo dedup repo4 repo3 2>err && (
        cd repo3 &&
        git silo checkout --link -- b c
    ) &&
    assertLinkCount repo3/b 2 &&
    assertLinkCount repo4/b 2 &&
    assertLinkCount repo3/c 2 &&
    assertLinkCount repo4/c 2 &&
    grep -i warning err
'

test_done
