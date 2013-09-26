#!/bin/bash

test_description='
Test that "silo fetch" correctly handles submodules that use a ".git" file to
redirect to the real repository location.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup user" '
    setup_user
'

test_expect_success "setup submodule" '
    mkdir super && (
        cd super &&
        git init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m "initial commit" &&
        mkdir sub && (
            cd sub &&
            git init &&
            touch .gitignore &&
            git add .gitignore &&
            git commit -m "initial commit" &&
            git silo init
            echo a >a &&
            git silo add a &&
            git commit -m "Add a"
        ) &&
        git submodule add ./sub &&
        git commit -m "add sub"
    ) &&
    git clone super super2 && (
        cd super2 &&
        git submodule update --init && (
            cd sub &&
            git silo init &&
            git silo fetch -- .
        )
    )
'

test_expect_success "setup subcp" '
    git clone super2/sub subcp
'

for transport in scp sshtar; do
    repo=sub${transport}
    test_expect_success LOCALHOST "setup ${repo}" "
        setup_clone_ssh super2/sub ${repo} && (
            cd ${repo} &&
            git config silo.sshtransport ${transport}
        )
    "
done

run_tests() {
local req="$1"
local transport="$2"

test_expect_success $req \
"'silo fetch' (${transport}) should handle submodule that uses 'gitdir: ...' redirect." "(
    cd sub${transport} &&
    git silo init &&
    git silo fetch -- . &&
    git silo checkout a &&
    echo a >expected &&
    test_cmp expected a
)"

}

run_tests '' cp
run_tests LOCALHOST scp
run_tests LOCALHOST sshtar

test_done
