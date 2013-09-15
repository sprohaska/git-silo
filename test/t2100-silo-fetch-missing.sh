#!/bin/bash

test_description='
Test that "silo fetch" handles missing files.
'

. ./lib-silo.sh

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
"setup original repo" \
'
    setup_file a &&
    setup_file b &&
    setup_repo orig &&
    setup_add_file orig a &&
    setup_add_file orig b &&
    (
        cd orig &&
        rm -rf .git/silo/objects/$(cut -b 1-2 ../a.sha1)
    )
'

test_expect_success \
"'git-silo fetch' (scp) should not abort on missing objects." \
'
    setup_clone_ssh orig reposcp &&
    (
        cd reposcp &&
        git-silo init &&
        ( git-silo fetch -- . || true ) &&
        git-silo checkout b &&
        test -e b
    )
'

test_expect_success \
"'git-silo fetch' (cp) should not abort on missing objects." \
'
    git clone orig repocp &&
    (
        cd repocp &&
        git-silo init &&
        ( git-silo fetch -- . || true ) &&
        git-silo checkout b &&
        test -e b
    )
'

test_done
