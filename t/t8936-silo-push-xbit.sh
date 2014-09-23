#!/bin/bash

test_description='
Test that "silo push" preserves x-bit.
'

. ./lib-silo.sh

if ! test_have_prereq UNIX; then
    skip_all='skipping xbit tests on msysgit; xbit not supported.'
    test_done
fi

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup (cp)" '
    setup_user &&
    setup_file a &&
    setup_file x &&
    chmod a+x x &&
    setup_repo cporig
'

test_expect_success "push (cp)" '
    git clone cporig cpclone && (
        cd cpclone &&
        git silo init
    ) &&
    setup_add_file cpclone x && (
        cd cpclone &&
        git silo push -- .
    )
'

test_expect_success "push (cp) preserved x-bit" '
    assertRepoHasSiloObject cporig x &&
    ! [ -x "$(siloObjectPath cporig a)" ] &&
    [ -x "$(siloObjectPath cporig x)" ]
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success "setup (ssh)" '
    setup_user &&
    setup_file x &&
    chmod a+x x &&
    setup_repo sshorig
'

test_expect_success "push (ssh)" '
    setup_clone_ssh sshorig sshclone && (
        cd sshclone &&
        git silo init
    ) &&
    setup_add_file sshclone x && (
        cd sshclone &&
        git silo push -- .
    )
'

test_expect_success "push (ssh) preserved x-bit" '
    assertRepoHasSiloObject sshorig x &&
    ! [ -x "$(siloObjectPath sshorig a)" ] &&
    [ -x "$(siloObjectPath sshorig x)" ]
'

test_done
