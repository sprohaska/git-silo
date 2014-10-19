#!/bin/bash

test_description='
Test that push prefers silo.alternate over pushing via ssh.
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

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_file second &&
    setup_repo orig &&
    setup_repo orig2 &&
    setup_repo orig3 &&
    setup_clone_ssh orig clone && (
        cd clone &&
        git silo init
    )
'

test_expect_failure "'push' via ssh links to remote alternate." '
    setup_add_file orig2 first &&
    setup_add_file orig3 second &&
    setup_add_file clone first &&
    setup_add_file clone second && (
        cd orig &&
        git config --add silo.alternate ../invalid/alternate &&
        git config --add silo.alternate ../orig2 &&
        git config --add silo.alternate ../orig3
    ) && (
        cd clone &&
        git config silo.sshtransport sshcat &&
        git push origin HEAD:clone-master &&
        git silo push -- .
    ) && (
        cd orig &&
        git merge clone-master &&
        git silo checkout --link -- . &&
        assertLinkCount first 4 &&
        assertLinkCount second 4
    )
'

test_done
