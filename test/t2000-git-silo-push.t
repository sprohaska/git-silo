#!/bin/bash

test_description="git-silo push"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file a &&
    setup_repo repo1
'

test_expect_success \
"'git-silo push' (scp) should push." \
"
    setup_clone_ssh repo1 scpclone &&
    ( cd scpclone && git-silo init) &&
    setup_add_file scpclone a &&
    ( cd scpclone && git-silo push) &&
    ( cd repo1/.git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp a.sha1 actual
"

test_expect_success \
"'git-silo push' (scp) should skip files that are already at remote." \
"
    (
        cd scpclone &&
        git-silo push >actual &&
        ( ! grep -q 'scp ../..' actual || ( echo 'Found unexpected scp' && false ) ) &&
        git-silo push
    )
"

test_done
