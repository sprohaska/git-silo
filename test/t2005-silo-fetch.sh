#!/bin/bash

test_description='
Test basic "silo fetch" operations.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_repo repo1
'

test_expect_success \
"'git-silo fetch' should refuse to fetch without pathspec." '
    git clone repo1 refuse &&
    ( cd refuse && git-silo init && ! git-silo fetch )
'

test_expect_success "'git-silo fetch' (cp) should fetch" '
    git clone repo1 cpclone &&
    ( cd cpclone && git-silo init ) &&
    setup_add_file repo1 first &&
    ( cd cpclone && git pull && git-silo fetch -- . ) &&
    ( cd cpclone/.git/silo/objects && find * -type f | sed -e "s@/@@" ) >actual &&
    test_cmp first.sha1 actual
'

test_expect_success "local fetch should use hardlinks" '
    echo 3 >expected &&
    linkCount cpclone/.git/silo/objects/*/* >actual &&
    test_cmp expected actual
'

test_expect_success "cleanup" '
    rm -f cpclone/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo fetch --dry-run' report files without fetching." '
    ( cd cpclone && git-silo fetch --dry-run -- . ) >log &&
    grep -q first log &&
    printf "" >expected &&
    ( find cpclone/.git/silo/objects -type f ) >actual &&
    test_cmp expected actual
'

test_expect_success "cleanup" '
    rm -f cpclone/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo fetch' should mention files that are fetched." '
    ( cd cpclone && git-silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo fetch' should not mention files that are already up-to-date." '
    ( cd cpclone && git-silo fetch -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"'git-silo fetch' should support named remote." '
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
"'git-silo fetch' (scp) should fetch" '
    setup_clone_ssh repo1 scpclone &&
    (
        cd scpclone &&
        git-silo init &&
        git-silo fetch -- .
    ) &&
    ( cd scpclone/.git/silo/objects && find * -type f | sed -e "s@/@@" ) >actual &&
    test_cmp first.sha1 actual
'

test_expect_success "cleanup" '
    rm -f scpclone/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo fetch' should mention files that are fetched." '
    ( cd scpclone && git-silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo fetch' should not mention files that are already up-to-date." '
    ( cd scpclone && git-silo fetch -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"'git-silo fetch' should report error with invalid remote path." '
    (
        cd scpclone &&
        git remote add invalid ssh://localhost/invalid/path &&
        ! git silo fetch invalid -- .
    )
'

test_expect_success \
"'git-silo fetch' should ignore missing remote silo/objects." '
    rm -rf repo1/.git/silo/objects &&
    (
        cd scpclone &&
        git silo fetch -- .
    )
'

test_done
