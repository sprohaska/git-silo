#!/bin/bash

test_description='
Test that "silo push" properly maintains shared permissions.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_repo repo1 --shared
'

test_expect_success "setup (cp)" '
    git clone repo1 cpclone && (
        cd cpclone &&
        git silo init
    )
'

for transport in scp sshtar; do
    repo="${transport}clone"
    test_expect_success LOCALHOST "setup ${repo}" "
        setup_clone_ssh repo1 ${repo} && (
            cd ${repo} &&
            git config silo.sshtransport ${transport} &&
            git silo init
        )
    "
done

run_tests() {
local req=$1
local transport=$2
local prefix=$3
local clone="${transport}clone"

test_expect_success $req \
"'git silo push' (${transport}) should create dir with shared permissions when pushing to shared repo." "
    setup_file ${prefix}1 &&
    setup_add_file ${clone} ${prefix}1 &&
    (
        cd ${clone} &&
        git silo push -- .
    ) && (
        cd repo1 &&
        isSharedDir .git/silo/objects/\$(cut -b 1-2 ../${prefix}1.sha1)
    )
"

test_expect_success $req \
"'git silo push' (${transport}) should set group write bit in shared repo even when file in local repo is not group readable." "
    setup_file ${prefix}2 &&
    setup_add_file ${clone} ${prefix}2 && (
        cd ${clone} &&
        chmod g-r ${prefix}2 &&
        git silo push -- .
    ) && (
        cd repo1 && (
            ls -l .git/silo/objects/\$(cut -b 1-2 ../${prefix}2.sha1)/\$(cut -b 3-40 ../${prefix}2.sha1) |
            grep -q '^-r--r--'
        )
    )
"

test_expect_success $req \
"'git silo push' (${transport}) should fail with 'missing silo dir' when pushing to unitialized repo." "
    mv repo1/.git/silo repo1/.git/silo-tmp && (
        cd ${clone} &&
        ! git silo push -- . 2>../stderr
    ) &&
    grep -qi 'missing silo dir' stderr &&
    mv repo1/.git/silo-tmp repo1/.git/silo
"

}

run_tests UNIX cp a
run_tests LOCALHOST scp b
run_tests LOCALHOST sshtar c

test_done
