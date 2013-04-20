#!/bin/bash

test_description="git-silo init"

. ./_testinglib.sh

test_expect_success \
"'git-silo init' should succeed." \
'
    mkdir single &&
    ( cd single && git init && git-silo init )
'

test_expect_success \
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

test_expect_success \
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

test_done
