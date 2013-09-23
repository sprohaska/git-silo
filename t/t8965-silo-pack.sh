#!/bin/bash

test_description='
Test packing (WIP)
'

. ./lib-silo.sh

numObjects() {
    find .git/silo/objects -type f |
    wc -l |
    sed -e 's/ *//g'
}

assertNumObjects() {
    [ $(numObjects) == $1 ]
}

test_expect_success 'setup' '
    setup_user &&
    setup_repo repo &&
    ( cd repo && git config silo.packSizeLimit 8K )
'

test_expect_success 'pack should handle empty silo' '
    (
        cd repo &&
        git silo pack
    )
'

test_expect_success 'setup files (1..5)' '
    (
        cd repo &&
        for i in $(seq 1 5); do
            printf "%${i}024d" $i >$i &&
            git silo add $i ||
            error "failed to setup file $i."
        done &&
        git commit -m "add files"
    )
'

test_expect_success 'pack should succeed.' '
    (
        cd repo &&
        git silo pack
    )
'

test_expect_success "'pack --keep' should keep loose objects." '
    (
        cd repo &&
        git silo pack --keep &&
        assertNumObjects 5
    )
'

test_expect_success "'pack --remove' should remove loose objects." '
    (
        cd repo &&
        git silo pack --remove &&
        assertNumObjects 0
    )
'

test_expect_success "'unpack 1' should create one loose object." '
    (
        cd repo &&
        git silo unpack 1 &&
        assertNumObjects 1
    )
'

test_expect_success "'unpack' should create all 5 loose object." '
    (
        cd repo &&
        git silo unpack &&
        assertNumObjects 5
    )
'

test_expect_success "setup shared repo." '
    setup_repo sharedrepo --shared &&
    setup_file a &&
    setup_add_file sharedrepo a
'

test_expect_success "'unpack' should maintain shared permissions." '
    (
        cd sharedrepo &&
        git silo pack --remove &&
        git silo unpack &&
        isSharedDir .git/silo/objects/$(cut -b 1-2 ../a.sha1)
    )
'

test_expect_success 'setup files (6..10)' '
    (
        cd repo &&
        for i in $(seq 6 10); do
            printf "%${i}024d" $i >$i &&
            git silo add $i ||
            error "failed to setup file $i."
        done &&
        git commit -m "add files"
    )
'

test_expect_success 'pack should succeed.' '
    (
        cd repo &&
        git silo pack
    )
'

test_expect_success 'setup files (11..99)' '
    (
        cd repo &&
        for i in $(seq 11 99); do
            printf "%3${i}0d" $i >$i &&
            git silo add $i ||
            error "failed to setup file $i."
        done &&
        git commit -m "add files"
    )
'

test_expect_success "'pack --remove' should keep 2 (large) loose objects." '
    (
        cd repo &&
        git silo pack --remove &&
        assertNumObjects 2
    )
'

test_expect_success "'unpack' should create all 99 loose object." '
    (
        cd repo &&
        git silo unpack &&
        assertNumObjects 99
    )
'

test_expect_success "'unpack' should only create loose objects used by HEAD." '
    (
        cd repo &&
        git rm 9? &&
        git commit -m "remove 9?" &&
        git silo pack --remove &&
        assertNumObjects 2 &&
        git silo unpack &&
        assertNumObjects 89
    )
'

test_done
