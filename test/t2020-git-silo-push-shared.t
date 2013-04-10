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
    setup_repo repo1 --shared &&
    git clone repo1 cpclone &&
    ( cd cpclone && git-silo init ) &&
    setup_add_file cpclone a
'

test_expect_success \
"'git-silo push' (cp) should create dir with shared permissions when pushing to shared repo." \
'
    ( cd cpclone && git-silo push )
    ( cd repo1 && isSharedDir .git/silo/objects/$(cut -b 1-2 ../a.sha1) )
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"setup (ssh)" \
'
    setup_clone_ssh repo1 scpclone &&
    ( cd scpclone && git-silo init ) &&
    setup_add_file scpclone b
'

test_expect_success \
"'git-silo push' (scp) should create dir with shared permissions when pushing to shared repo." \
'
    ( cd scpclone && git-silo push ) &&
    ( cd repo1 && isSharedDir .git/silo/objects/$(cut -b 1-2 ../b.sha1) )
'

test_done
