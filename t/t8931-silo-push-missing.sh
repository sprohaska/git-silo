#!/bin/bash

test_description='
Test that "silo push" handles missing files.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    setup_add_file repo1 a &&
    setup_add_file repo1 b &&
    git clone repo1 cpclone
'

for transport in scp sshtar sshcat; do
    repo="${transport}clone"
    test_expect_success LOCALHOST "setup ${repo}" "
        setup_clone_ssh repo1 ${repo} && (
            cd ${repo} &&
            git config silo.sshtransport ${transport}
        )
    "
done

run_tests() {
local req="$1"
local transport="$2"
local clone="${transport}clone"

test_expect_success $req \
"'git silo push' (${transport}) should skip missing files." "
    (
        cd ${clone} &&
        git silo init &&
        git silo fetch -- a
    ) &&
    rm -rf repo1/.git/silo/objects/* && (
        cd ${clone} &&
        git silo push -- .
    )
"

}  # run_tests

run_tests '' cp
run_tests LOCALHOST scp
run_tests LOCALHOST sshtar
run_tests LOCALHOST sshcat

test_done
