#!/bin/bash

test_description='
Test that "silo fetch" keeps x-bit.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup user" '
    setup_user
'

test_expect_success "setup repo" '
    setup_file a &&
    setup_file x &&
    chmod a+x x &&
    setup_repo orig &&
    setup_add_file orig a &&
    setup_add_file orig x
'

test_expect_success "fetch (cp)" '
    git clone orig cpclone && (
        cd cpclone &&
        git silo init &&
        git silo fetch -- .
    )
'

test_expect_success "clone (cp) has x bit" '
    ! [ -x "$(siloObjectPath cpclone a)" ] &&
    [ -x "$(siloObjectPath cpclone x)" ]
'

test_expect_success LOCALHOST "fetch (ssh)" '
    setup_clone_ssh orig sshcatclone && (
        cd sshcatclone &&
        git silo init &&
        git config silo.sshtransport sshcat &&
        git silo fetch -- .
    )
'

test_expect_success "clone (ssh) has x bit" '
    ! [ -x "$(siloObjectPath sshcatclone a)" ] &&
    [ -x "$(siloObjectPath sshcatclone x)" ]
'

test_done
