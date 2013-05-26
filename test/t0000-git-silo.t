#!/bin/bash

test_description="git-silo init"

. ./_testinglib.sh

test_expect_success \
"'git-silo init' should succeed." \
'
    mkdir single &&
    ( cd single && git init && git-silo init )
'

test_expect_success UNIX \
"'git-silo init' should use shared permissions when repo is shared." \
'
    mkdir shared &&
    (
        cd shared &&
        git init --shared &&
        git-silo init &&
        ( ls -ld .git/silo/objects | grep -q "^drwxrws" )
    )
'

test_expect_success UNIX \
"'git-silo init' should preserve read-only permissions of files when run twice." \
'
    (
        cd shared &&
        touch a &&
        git silo add a &&
        ( ls -ld .git/silo/objects/*/* | grep -q "^-r--r--" ) &&
        git-silo init &&
        ( ls -ld .git/silo/objects/*/* | grep -q "^-r--r--" )
    )
'

test_expect_success \
"'git silo init' should set up correct filter path, in particular on Windows." \
'
    mkdir win &&
    (
        cd win &&
        git silo init &&
        touch a &&
        git silo add a 2>log &&
        ! grep error: log
    )
'

test_done
