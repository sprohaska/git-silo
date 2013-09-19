#!/bin/bash

test_description='
Test "silo fsck" to verify consistency of silo store.
'

. ./lib-silo.sh

test_expect_success 'setup (empty repo)' '
    setup_user &&
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git silo init
'

test_expect_success 'silo fsck should handle empty repo' '
    git silo fsck
'

test_expect_success 'setup (add files)' '
    echo a >a &&
    git silo add a &&
    git commit -m "Add a"
'

test_expect_success 'git silo fsck should exit with zero when repo ok.' '
    git silo fsck
'

test_expect_success 'git silo fsck should print ok when repo ok.' '
    git silo fsck | grep -q ok
'

test_expect_success \
'git silo fsck should exit with nonzero when repo corrupted.' '
    chmod u+w a &&
    echo "corrupted" >>a &&
    ! git silo fsck
'

test_done
