#!/bin/bash

test_description='
Test that config silo.contentSizeLimit controls whether placeholder or content
is used.
'

. ./lib-silo.sh

# Create 1GB as multiple lines to avoid malloc failure in msysgit during
# creation and during 'head | grep'.
test_expect_success 'setup' '
    setup_user &&
    setup_repo repo &&
    printf "%1024d" 0 >1KB &&
    setup_add_file repo 1KB &&
    printf "%1048576d" 0 >1MB &&
    setup_add_file repo 1MB &&
    for i in {1..1024}; do
        printf "%1048575d\n" 0 >>1GB
    done &&
    setup_add_file repo 1GB
'

assertContent() {
    local path=$1
    if ! head -n 1 "${path}" | egrep -q '^[0-9a-z]{40}$'; then
        return 0
    fi
    printf "Assertion failed: '%s' is a placeholder.\n" "${path}"
    return 1
}

assertPlaceholder() {
    local path=$1
    head -n 1 "${path}" | egrep -q '^[0-9a-z]{40}$' && return 0
    printf "Assertion failed: '%s' is not a placeholder.\n" "${path}"
    return 1
}

test_expect_success \
'content 1KB, 1MB; placeholder 1GB when silo.contentSizeLimit is unset' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertContent 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success \
'placeholder 1KB, 1MB, 1GB when silo.contentSizeLimit=1024' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1024 &&
        git reset --hard HEAD &&
        assertPlaceholder 1KB &&
        assertPlaceholder 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success \
'content 1KB; placeholder 1MB, 1GB when silo.contentSizeLimit=1048576' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1048576 &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertPlaceholder 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success \
'content 1KB, 1MB; placeholder 1GB when silo.contentSizeLimit=1073741824' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1073741824 &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertContent 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success 'placeholder 1KB, 1MB, 1GB when silo.contentSizeLimit=1K' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1K &&
        git reset --hard HEAD &&
        assertPlaceholder 1KB &&
        assertPlaceholder 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success \
'content 1KB; placeholder 1MB, 1GB when silo.contentSizeLimit=1M' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1M &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertPlaceholder 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success \
'content 1KB, 1MB; placeholder 1GB when silo.contentSizeLimit=1G' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 1G &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertContent 1MB &&
        assertPlaceholder 1GB
    )
'

test_expect_success 'content 1KB, 1MB, 1GB when silo.contentSizeLimit=0' '
    (
        cd repo &&
        rm -f 1KB 1MB 1GB &&
        git config silo.contentSizeLimit 0 &&
        git reset --hard HEAD &&
        assertContent 1KB &&
        assertContent 1MB &&
        assertContent 1GB
    )
'

test_done
