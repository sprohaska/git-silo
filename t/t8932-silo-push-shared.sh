#!/bin/bash

test_description='
Test that "silo push" properly maintains shared permissions.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_repo repo1 --shared &&
    git clone repo1 cpclone && (
        cd cpclone &&
        git silo init
    ) &&
    setup_file a &&
    setup_add_file cpclone a
'

test_expect_success LOCALHOST "setup (ssh)" '
    setup_clone_ssh repo1 scpclone && (
        cd scpclone &&
        git silo init
    ) &&
    setup_file b &&
    setup_add_file scpclone b
'

test_expect_success UNIX \
"'git silo push' (cp) should create dir with shared permissions when pushing to shared repo." '
    (
        cd cpclone &&
        git silo push -- .
    ) && (
        cd repo1 &&
        isSharedDir .git/silo/objects/$(cut -b 1-2 ../a.sha1)
    )
'

test_expect_success LOCALHOST \
"'git silo push' (scp) should create dir with shared permissions when pushing to shared repo." '
    (
        cd scpclone &&
        git silo push -- .
    ) && (
        cd repo1 &&
        isSharedDir .git/silo/objects/$(cut -b 1-2 ../b.sha1)
    )
'

test_expect_success UNIX \
"'git silo push' (cp) should set group write bit in shared repo even when file in local repo is not group readable." \
'
    setup_file c &&
    setup_add_file cpclone c && (
        cd cpclone &&
        chmod g-r c &&
        git silo push -- .
    ) && (
        cd repo1 &&
        ( ls -l .git/silo/objects/$(cut -b 1-2 ../c.sha1)/$(cut -b 3-40 ../c.sha1) | grep -q "^-r--r--" )
    )
'

test_expect_success LOCALHOST \
"'git silo push' (scp) should set group write bit in shared repo even when file in local repo is not group readable." \
'
    setup_file d &&
    setup_add_file scpclone d && (
        cd scpclone &&
        chmod g-r d &&
        git silo push -- .
    ) && (
        cd repo1 &&
        ( ls -l .git/silo/objects/$(cut -b 1-2 ../d.sha1)/$(cut -b 3-40 ../d.sha1) | grep -q "^-r--r--" )
    )
'

test_expect_success UNIX \
"'git silo push' (cp) should fail with 'missing silo dir' when pushing to unitialized repo." '
    (
        cd repo1 &&
        rm -rf .git/silo
    ) && (
        cd cpclone &&
        ! git silo push -- . 2>../stderr
    ) &&
    grep -qi "missing silo dir" stderr
'

test_expect_success LOCALHOST \
"'git silo push' (scp) should fail with 'missing silo dir' when pushing to unitialized repo." '
    (
        cd repo1 &&
        rm -rf .git/silo
    ) && (
        cd scpclone &&
        ! git silo push -- . 2>../stderr
    ) &&
    grep -qi "missing silo dir" stderr
'

test_done
