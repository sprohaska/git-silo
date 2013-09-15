#!/bin/bash

test_description='
Test basic "silo push" operations.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file first &&
    setup_repo repo1
'

test_expect_success \
"'git-silo push' should refuse to push without path." \
"
    git clone repo1 refuse &&
    ( cd refuse && git-silo init && ! git-silo push )
"

test_expect_success \
"'git-silo push' (cp) should push." \
"
    git clone repo1 cpclone &&
    ( cd cpclone && git-silo init) &&
    setup_add_file cpclone first &&
    ( cd cpclone && git-silo push -- .) &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp first.sha1 actual
"

test_expect_success \
"cleanup" \
'
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo push' should support named remote." \
'
    git clone repo1 namedorigin &&
    (
        cd namedorigin &&
        git remote rename origin org &&
        git-silo init
    ) &&
    setup_add_file namedorigin first &&
    ( cd namedorigin && git-silo push org -- . ) &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e "s@/@@" ) >actual &&
    test_cmp first.sha1 actual
'

test_expect_success \
"cleanup" \
'
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo push' should mention files that are pushed." \
'
    ( cd cpclone && git-silo push -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo push' should not mention files that are already up-to-date." \
'
    ( cd cpclone && git-silo push -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"cleanup" \
'
    rm -f repo1/.git/silo/objects/*/*
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"'git-silo push' (scp) should push." \
"
    setup_clone_ssh repo1 scpclone &&
    ( cd scpclone && git-silo init) &&
    setup_add_file scpclone first &&
    ( cd scpclone && git-silo push -- .) &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp first.sha1 actual
"

test_expect_success \
"cleanup" \
'
    rm -f repo1/.git/silo/objects/*/*
'

test_expect_success \
"'git-silo push' should mention files that are pushed." \
'
    ( cd scpclone && git-silo push -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'git-silo push' should not mention files that are already up-to-date." \
'
    ( cd scpclone && git-silo push -- . ) >log &&
    ! grep -q first log
'

test_done
