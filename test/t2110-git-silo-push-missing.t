#!/bin/bash

test_description="git-silo push"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file a &&
    setup_file b &&
    setup_repo repo1 &&
    setup_add_file repo1 a &&
    setup_add_file repo1 b &&
    git clone repo1 cpclone
'

test_expect_success \
    "'git-silo push' (cp) should skip missing files." \
'
    ( cd cpclone && git-silo init && git-silo fetch a ) &&
    rm -rf repo1/.git/silo/objects/* &&
    ( cd cpclone && git-silo push -- . )
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"'git-silo push' (scp) should skip missing files." \
'
    setup_clone_ssh repo1 scpclone &&
    ( cd scpclone && git-silo init && git-silo fetch a ) &&
    rm -rf repo1/.git/silo/objects/* &&
    ( cd scpclone && git-silo push -- . )
'

test_done
