#!/bin/bash

test_description="git-silo push"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"setup user" \
'
    setup_user
'

test_expect_success \
"'git-silo push' (scp) should push." \
"
    echo a >a &&
    ( openssl sha1 a | cut -d ' ' -f 2 > a.sha1 ) &&
    mkdir repo1 &&
    (
        cd repo1 &&
        git init &&
        git-silo init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m 'initial commit'
    ) &&
    setup_clone_ssh repo1 repo2 &&
    (
        cd repo2 &&
        git-silo init &&
        cp ../a a &&
        git-silo add a &&
        git commit -m 'Add a' &&
        git-silo push
    ) &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp a.sha1 actual
"

test_expect_success \
"'git-silo push' (scp) should skip files that are already at remote." \
"
    (
        cd repo2 &&
        git-silo push >actual &&
        ( ! grep -q 'scp ../..' actual || ( echo 'Found unexpected scp' && false ) ) &&
        git-silo push
    )
"

test_done
