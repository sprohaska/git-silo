#!/bin/bash

test_description="git-silo fetch"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file first &&
    setup_repo repo1
'

test_expect_success \
"'git-silo fetch' should refuse to fetch without pathspec." \
'
    git clone repo1 refuse &&
    ( cd refuse && git-silo init && ! git-silo fetch )
'

test_expect_success \
"'git-silo fetch' (cp) should fetch" \
"
    git clone repo1 cpclone &&
    ( cd cpclone && git-silo init ) &&
    setup_add_file repo1 first &&
    ( cd cpclone && git pull && git-silo fetch -- . ) &&
    ( cd cpclone/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp first.sha1 actual
"

test_expect_success \
"cleanup" \
'
    rm -f cpclone/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo fetch' should mention files that are fetched." \
'
    ( cd cpclone && git-silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo fetch' should not mention files that are already up-to-date." \
'
    ( cd cpclone && git-silo fetch -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"'git-silo fetch' should support named remote." \
'
    git clone repo1 namedorigin &&
    (
        cd namedorigin &&
        git remote rename origin org &&
        git-silo init &&
        git silo fetch org -- .
    ) && (
        cd namedorigin/.git/silo/objects &&
        find * -type f | sed -e "s@/@@"
    ) >actual &&
    test_cmp first.sha1 actual
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"'git-silo fetch' (scp) should fetch" \
"
    setup_clone_ssh repo1 scpclone &&
    (
        cd scpclone &&
        git-silo init &&
        git-silo fetch -- .
    ) &&
    ( cd scpclone/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp first.sha1 actual
"

test_expect_success \
"cleanup" \
'
    rm -f scpclone/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo fetch' should mention files that are fetched." \
'
    ( cd scpclone && git-silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo fetch' should not mention files that are already up-to-date." \
'
    ( cd scpclone && git-silo fetch -- . ) >log &&
    ! grep -q first log
'

test_done
