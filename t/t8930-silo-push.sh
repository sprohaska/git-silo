#!/bin/bash

test_description='
Test basic "silo push" operations.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_repo repo1
'

test_expect_success "'silo push' should refuse to push without path." '
    git clone repo1 refuse && (
        cd refuse &&
        git silo init &&
        ! git silo push
    )
'

test_expect_success "'silo push' (cp) should push." '
    git clone repo1 cpclone && (
        cd cpclone &&
        git silo init
    ) &&
    setup_add_file cpclone first && (
        cd cpclone &&
        git silo push -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_expect_success "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success "'silo push' should support named remote." '
    git clone repo1 namedorigin && (
        cd namedorigin &&
        git remote rename origin org &&
        git silo init
    ) &&
    setup_add_file namedorigin first && (
        cd namedorigin &&
        git silo push org -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_expect_success "'silo push' should push to relative path." '
    rm -f repo1/.git/silo/objects/*/* && (
        cd namedorigin &&
        git silo push ../repo1 -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_expect_success "'silo push' should push to absolute path." '
    rm -f repo1/.git/silo/objects/*/* && (
        cd namedorigin &&
        git silo push "$(cd ../repo1 && pwd)" -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_expect_success "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success "'silo push' should mention files that are pushed." '
    ( cd cpclone && git silo push -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'silo push' should not mention files that are already up-to-date." '
    ( cd cpclone && git silo push -- . ) >log &&
    ! grep -q first log
'

test_expect_success "'silo push' should push specific revision." '
    rm -f repo1/.git/silo/objects/*/* && (
        cd namedorigin &&
        git checkout HEAD~1 &&
        git silo push org master -- . &&
        git checkout master
    ) &&
    assertRepoHasSiloObject repo1 first
'

ssh_tests_with_transport() {
local transport="$1"
local clone="${transport}clone"

test_expect_success LOCALHOST "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
    rmdir repo1/.git/silo/objects/*
'

test_expect_success LOCALHOST "'silo push' (${transport}) should push." "
    setup_clone_ssh repo1 ${clone} && (
        cd ${clone} &&
        git config silo.sshtransport ${transport} &&
        git silo init
    ) &&
    setup_add_file ${clone} first && (
        cd ${clone} &&
        git silo push -- .
    ) &&
    assertRepoHasSiloObject repo1 first
"

test_expect_success LOCALHOST "'silo push' (${transport}) should push." "
    rm -f repo1/.git/silo/objects/*/* && (
        cd ${clone} &&
        git silo push 'ssh://localhost$(cd repo1 && pwd)' -- .
    ) &&
    assertRepoHasSiloObject repo1 first
"

test_expect_success LOCALHOST "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success LOCALHOST "'silo push' (${transport}) should mention files that are pushed." "
    ( cd ${clone} && git silo push -- . ) >log &&
    grep -q first log
"

test_expect_success LOCALHOST \
"'silo push' (${transport}) should not mention files that are already up-to-date." "
    ( cd ${clone} && git silo push -- . ) >log &&
    ! grep -q first log
"

}  # ssh_tests_with_transport

ssh_tests_with_transport sshcat

test_expect_success LOCALHOST "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
    rmdir repo1/.git/silo/objects/*
'

test_expect_success LOCALHOST "'silo push' (sshcat) should detect corrupted files." '
    setup_clone_ssh repo1 corrupted && (
        cd corrupted &&
        git config silo.sshtransport sshcat &&
        git silo init
    ) &&
    setup_add_file corrupted first && (
        cd corrupted &&
        chmod u+w .git/silo/objects/*/* &&
        echo corrupted-data >.git/silo/objects/*/* &&
        ! git silo push -- . 2>err &&
        grep -q -i "checksum" err
    )
'

test_done
