#!/bin/bash

test_description='
Test automatic unpack
'

. ./lib-silo.sh

if ! type 7zr >/dev/null 2>&1; then
    skip_all='Skipping tests, because 7zr is not available.'
    test_done
fi

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_repo repo1
'

test_expect_success "push (cp) should autounpack." '
    git clone repo1 cpclone && (
        cd cpclone &&
        git silo init
    ) &&
    setup_add_file cpclone first && (
        cd cpclone &&
        git silo pack --all --prune &&
        git config silo.autounpack true &&
        git silo push -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_expect_success "cleanup" '
    rm -f repo1/.git/silo/objects/*/*
    rmdir repo1/.git/silo/objects/*
'

test_expect_success "push (sshcat) should autounpack." '
    setup_clone_ssh repo1 sshclone && (
        cd sshclone &&
        git silo init
    ) &&
    setup_add_file sshclone first && (
        cd sshclone &&
        git silo pack --all --prune &&
        git config silo.autounpack true &&
        git silo push -- .
    ) &&
    assertRepoHasSiloObject repo1 first
'

test_done
