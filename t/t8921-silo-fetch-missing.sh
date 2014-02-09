#!/bin/bash

test_description='
Test that "silo fetch" handles missing files.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup user" '
    setup_user
'

test_expect_success "setup original repo" '
    setup_file a &&
    setup_file b &&
    setup_repo orig &&
    setup_add_file orig a &&
    setup_add_file orig b && (
        cd orig &&
        rm -rf .git/silo/objects/$(cut -b 1-2 ../a.sha1)
    )
'

test_expect_success "setup cpclone" '
    git clone orig cpclone && (
        cd cpclone &&
        git silo init
    )
'

test_expect_success LOCALHOST "setup sshcatclone" '
    setup_clone_ssh orig sshcatclone && (
        cd sshcatclone &&
        git silo init &&
        git config silo.sshtransport sshcat
    )
'

run_tests() {
local req="$1"
local transport="$2"
local clone="${transport}clone"

test_expect_success $req \
"'silo fetch' (${transport}) should continue if some objects are missing and finally report error." "(
    cd ${clone} &&
    ! git silo fetch -- . 2>stderr &&
    grep -qi 'files are missing' stderr &&
    git silo checkout b &&
    test -e b
)"

}  # ssh_tests_with_transport

run_tests '' cp
run_tests LOCALHOST sshcat

test_done
