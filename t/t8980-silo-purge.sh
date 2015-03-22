#!/bin/bash

test_description='
Test purge operations of files from working copy and silo store.
'

. ./lib-silo.sh

test_expect_success "setup" '
    setup_user &&
    setup_file a &&
    setup_file b
'

cdNewRepo() {
    cdNewMasterRepo
    git config silo.ismasterstore false
}

cdNewMasterRepo() {
    local idx=1
    local r=repo${idx}
    while [[ -d $r ]]; do
        (( idx++ ))
        r=repo${idx}
    done
    setup_repo $r &&
    setup_add_file $r a &&
    setup_add_file $r b &&
    cd $r
}

test_expect_success \
"'git silo purge' should refuse to run if silo.ismasterstore is unset." '(
    cdNewMasterRepo &&
    ! git silo purge -f -- a
)'

test_expect_success \
"'git silo purge' should refuse to run if silo.ismasterstore=true." '(
    cdNewMasterRepo &&
    git config silo.ismasterstore true &&
    ! git silo purge -f -- a
)'

test_expect_success "'git silo purge' should refuse to run without '-f'." '(
    cdNewRepo &&
    ! git silo purge -- a
)'

test_expect_success "'git silo purge' should refuse to run without pathspec." '(
    cdNewRepo &&
    ! git silo purge -f
)'

test_expect_success \
"'git silo purge --dry-run -- <path>' should report path." '
    (
        cdNewRepo &&
        git silo purge --dry-run -- b >../log 2>&1
    ) &&
    grep -q -i "would remove.*b" log
'

test_expect_success "'git silo purge -f -- <path>' should purge path" '(
    cdNewRepo &&
    git silo purge -f -- b &&
    test_cmp ../b.sha1 b &&
    rm b &&
    ! git silo checkout -- b
)'

test_expect_success "'git silo purge' refuses to purge with invalid silo.masterstore" '(
    cdNewRepo &&
    git config silo.masterstore /invalid/path/ &&
    ! git silo purge -f -- b &&
    test_cmp ../b b
)'

test_expect_success "'git silo purge' refuses to purge if file is missing in silo.masterstore" '(
    cdNewRepo &&
    git silo purge -f -- a &&
    master="$(pwd)" &&
    cd .. &&
    cdNewRepo &&
    git config silo.masterstore "${master}" &&
    ! git silo purge -f -- a b &&
    test_cmp ../a a &&
    test_cmp ../b b &&
    git silo purge -f -- b &&
    ! git silo purge -f -- a &&
    test_cmp ../a a
)'

test_expect_success \
"'git silo purge -- <path>' should be quiet if nothing to do." '(
    cdNewRepo &&
    git silo purge -f -- . &&
    [ "$(git silo purge -f -- .)" == "" ]
)'

test_expect_success \
"'git silo purge -f -- <path>' should leave workspace in clean state." '(
    cdNewRepo &&
    git silo purge -f -- b &&
    [ "$(git status --porcelain)" == "" ]
)'

test_expect_success \
"'git silo purge -f -- <path>' should remove empty silo/object subdirs." '(
    cdNewRepo &&
    git silo purge -f -- . &&
    [ "$(find .git/silo/objects -mindepth 1 -maxdepth 1)" == "" ] &&
    git silo purge -f -- . &&
    [ -d .git/silo/objects ]
)'

test_expect_success \
"'git silo purge -f -- <path>' should replace content with placeholder but keep aliased object." '(
    cdNewRepo &&
    cp b b2 &&
    git silo add --attr b2 &&
    git commit -m "Add b2" &&
    git silo purge -f -- b &&
    test_cmp ../b.sha1 b &&
    test_cmp ../b b2 &&
    rm b2 &&
    git silo checkout -- b2
)'

test_done
