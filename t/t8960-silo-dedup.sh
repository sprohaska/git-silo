#!/bin/bash

test_description='
Test deduplication.
'

. ./lib-silo.sh

assertLinkCount() {
    local path=$1
    local expected=$2
    if ! test $(linkCount "$path") -eq $expected; then
        echo "Wrong link count $path (expected $expected)."
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

test_done
