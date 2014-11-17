#!/bin/bash

test_description='
Test that "silo add" uses silo.alternate to avoid computing sha1.
'

. ./lib-silo.sh

if ! test_have_prereq ASSUME_UNCHANGED_ONCE; then
    skip_all='skipping alternate tests; missing --assume-unchanged-once.'
    test_done
fi

# Sleep to avoid racy git when adding file below.
test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_file second &&
    chmod a+x second &&
    setup_repo alternate1 &&
    setup_add_file alternate1 first &&
    setup_repo alternate2 &&
    setup_add_file alternate2 second &&
    sleep 1
'

test_expect_success \
"'silo add' uses sha1 from alternate without calling clean filter." '(
    setup_repo repo &&
    cd repo &&
    git config --add silo.alternate ../alternate1 &&
    git config --add silo.alternate ../alternate2 &&
    ln ../alternate1/first . &&
    ln ../alternate2/second . &&
    echo "echo >&2 clean" >>.git/silo/bin/clean &&
    git silo add --attr -- first second 2>err &&
    ! grep -q clean err &&
    ( git ls-files -s -- first | grep -q ^100644 ) &&
    ( git ls-files -s -- second | grep -q ^100755 ) &&
    assertRepoHasNumSiloObjects . 2 &&
    git commit -m commit
)'

# sleep to avoid racy git.
test_expect_success \
"'silo add' should re-add files." '(
    cd repo &&
    rm -f .git/silo/objects/*/* &&
    touch first second &&
    sleep 1 &&
    git silo add --attr -- first second 2>err &&
    ! grep -q clean err &&
    ( git ls-files -s -- first | grep -q ^100644 ) &&
    ( git ls-files -s -- second | grep -q ^100755 ) &&
    assertRepoHasNumSiloObjects . 2
)'

# Sleep to avoid racy git.
test_expect_success \
"'silo add' works in subdir." '(
    cd repo &&
    mkdir subdir && (
        cd subdir &&
        ln ../first third &&
        sleep 1 &&
        git silo add --attr -- third 2>err &&
        ! grep -q clean err
    ) &&
    ( git ls-files -s -- subdir/third | grep -q ^100644 ) &&
    assertRepoHasNumSiloObjects . 2
)'

test_done
