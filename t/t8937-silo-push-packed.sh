#!/bin/bash

test_description='
Test interaction between push and packs.  Push should skip files that are
available in packs at remote.
'

. ./lib-silo.sh

if ! type 7zr >/dev/null 2>&1; then
    skip_all='Skipping tests, because 7zr is not available.'
    test_done
fi

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup orig" '
    setup_user &&
    setup_file first &&
    setup_repo orig &&
    setup_add_file orig first && (
        cd orig &&
        git config silo.autounpack true
    )
'

test_expect_success "setup cpclone" '
    git clone orig cpclone && (
        cd cpclone &&
        git silo init &&
        git silo fetch -- .
    )
'

test_expect_success "pack prune orig" '(
    cd orig &&
    git silo pack --prune --all
)'

test_expect_success \
"'silo push' should not push file that is packed at remote." '
    ( cd cpclone && git silo push -- . ) >log &&
    ! grep -q first log
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

ssh_tests_with_transport() {

local transport="$1"
local clone="${transport}clone"

test_expect_success "setup ${clone}" "
    setup_clone_ssh orig ${clone} && (
        cd ${clone} &&
        git config silo.sshtransport ${transport} &&
        git silo init &&
        git silo fetch -- .
    )
"

test_expect_success "pack prune orig" '(
    cd orig &&
    git silo pack --prune --all
)'

test_expect_success \
"'silo push' (${transport}) should not push file that is packed at remote." "
    ( cd ${clone} && git silo push -- . ) >log &&
    ! grep -q first log
"

}  # ssh_tests_with_transport

ssh_tests_with_transport sshcat

test_done
