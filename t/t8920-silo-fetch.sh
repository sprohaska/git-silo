#!/bin/bash

test_description='
Test basic "silo fetch" operations.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_file second &&
    setup_repo repo1
'

test_expect_success \
"'silo fetch' should refuse to fetch without pathspec." '
    git clone repo1 refuse &&
    ( cd refuse && git silo init && ! git silo fetch )
'

test_expect_success "'silo fetch' (cp) should fetch" '
    git clone repo1 cpclone &&
    ( cd cpclone && git silo init ) &&
    setup_add_file repo1 first &&
    setup_add_file repo1 second &&
    ( cd cpclone && git pull && git silo fetch -- . ) &&
    assertRepoHasSiloObject cpclone first
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
"'git silo fetch --dry-run' report files without fetching." '
    ( cd cpclone && git silo fetch --dry-run -- . ) >log &&
    grep -q first log &&
    assertRepoHasNumSiloObjects cpclone 0
'

test_expect_success "cleanup" '
    rm -f cpclone/.git/silo/objects/*/*
'

test_expect_success \
"'silo fetch' should mention files that are fetched." '
    ( cd cpclone && git silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'silo fetch' should not mention files that are already up-to-date." '
    ( cd cpclone && git silo fetch -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"'silo fetch' should support named remote." '
    git clone repo1 namedorigin && (
        cd namedorigin &&
        git remote rename origin org &&
        git silo init &&
        git silo fetch org -- .
    ) &&
    assertRepoHasSiloObject namedorigin first
'

test_expect_success "'silo fetch' should fetch from relative path." '
    rm -f namedorigin/.git/silo/objects/*/* && (
        cd namedorigin &&
        git silo fetch ../repo1 -- .
    ) &&
    assertRepoHasSiloObject namedorigin first
'

test_expect_success "'silo fetch' should fetch from absolute path." '
    rm -f namedorigin/.git/silo/objects/*/* && (
        cd namedorigin &&
        git silo fetch "$(cd ../repo1 && pwd)" -- .
    ) &&
    assertRepoHasSiloObject namedorigin first
'

test_expect_success "'silo fetch' should fetch specific revision." '
    rm -f namedorigin/.git/silo/objects/*/* && (
        cd namedorigin &&
        git checkout HEAD~2 &&
        git silo fetch org master -- . &&
        git checkout master
    ) &&
    assertRepoHasSiloObject namedorigin first
'

ssh_tests_with_transport() {
local transport="$1"

test_expect_success "setup sshclone (${transport})" "
    rm -rf sshclone &&
    setup_clone_ssh repo1 sshclone && (
        cd sshclone &&
        git silo init &&
        git config silo.sshtransport ${transport}
    )
"

test_expect_success \
"'silo fetch' (${transport}) should fetch" '
    (
        cd sshclone &&
        git silo fetch -- .
    ) &&
    assertRepoHasSiloObject sshclone first &&
    assertRepoHasSiloObject sshclone second
'

test_expect_success \
"'silo fetch' (${transport}) should fetch from url." '
    rm -f sshclone/.git/silo/objects/*/* && (
        cd sshclone &&
        git silo fetch "ssh://localhost$(cd ../repo1 && pwd)" -- .
    ) &&
    assertRepoHasSiloObject sshclone first
'

test_expect_success "cleanup" '
    rm -f sshclone/.git/silo/objects/*/*
'

test_expect_success \
"'silo fetch' (${transport}) should mention files that are fetched." '
    ( cd sshclone && git silo fetch -- . ) >log &&
    grep -q first log
'

test_expect_success \
"'silo fetch' (${transport}) should not mention files that are already up-to-date." '
    ( cd sshclone && git silo fetch -- . ) >log &&
    ! grep -q first log
'

test_expect_success \
"'silo fetch' (${transport}) should report error with invalid remote path." '(
    cd sshclone &&
    git remote add invalid ssh://localhost/invalid/path &&
    ! git silo fetch invalid -- .
)'

test_expect_success \
"'silo fetch' (${transport}) should ignore missing remote silo/objects." '
    mv repo1/.git/silo/objects repo1/.git/silo/objects-tmp && (
        cd sshclone &&
        git silo fetch -- .
    ) &&
    mv repo1/.git/silo/objects-tmp repo1/.git/silo/objects
'

}  # ssh_tests_with_transport

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

ssh_tests_with_transport sshcat

test_expect_success "'silo fetch' (sshcat) should detect corrupted object." '
    setup_repo corrupted &&
    setup_add_file corrupted first && (
        cd corrupted &&
        chmod u+w .git/silo/objects/*/* &&
        echo corrupted-data >.git/silo/objects/*/*
    ) &&
    setup_clone_ssh corrupted corruptedclone && (
        cd corruptedclone &&
        git silo init &&
        git config silo.sshtransport sshcat &&
        ! git silo fetch -- . 2>err &&
        grep -q -i "checksum" err
    )
'

test_done
