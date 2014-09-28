#!/bin/bash

test_description='
Test that fetch prefers silo.alternate over fetching via ssh.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping alternate tests; cannot ssh to localhost.'
    test_done
fi

assertLinkCount() {
    local file=$1
    local expected=$2
    local actual=$(linkCount "$1")
    [ $actual -eq $expected ] && return 0
    error "Wrong link count, expected ${expected}, actual ${actual}."
}

test_expect_success "setup orig" '
    setup_user &&
    setup_file first &&
    setup_repo orig &&
    setup_repo orig2 &&
    setup_add_file orig first
'

test_expect_success "'fetch' via ssh links to alternate." '
    setup_clone_ssh orig clone && (
        cd clone &&
        git config silo.sshtransport sshcat &&
        git silo init &&
        git config --add silo.alternate ../invalid/alternate &&
        git config --add silo.alternate ../orig2 &&
        git config --add silo.alternate ../orig &&
        git silo fetch -- . >out &&
        grep -i "linked to alternate" out &&
        git silo checkout -- first &&
        assertLinkCount first 4
    )
'

test_done
