#!/bin/bash

test_description='
Test basic "silo checkout" operations.
'

. ./lib-silo.sh

test_expect_success "setup" '
    setup_user &&
    setup_repo repo1 &&
    setup_file a &&
    setup_add_file repo1 a &&
    setup_file "ä ö" &&
    setup_add_file repo1 "ä ö"
'

test_expect_success "git checkout should replace placeholder file." '
    git clone repo1 repolf && (
        cd repolf &&
        git silo init &&
        git silo fetch -- . &&
        git silo checkout a &&
        test_cmp ../a a &&
        git silo status -- a | grep "^content *a" &&
        git silo checkout "ä ö" &&
        test_cmp "../ä ö" "ä ö" &&
        git silo status -- "ä ö" |
            grep "^content *\"[\\]303[\\]244 [\\]303[\\]266\""
    )
'

test_expect_success "checkout --placeholder creates placeholder." '(
    cd repolf &&
    git silo checkout --placeholder -- a &&
    test_cmp ../a.sha1 a &&
    git silo status -- a | grep "^placeholder" &&
    git silo checkout --placeholder -- "ä ö" &&
    test_cmp "../ä ö.sha1" "ä ö" &&
    git silo status -- "ä ö" |
        grep "^placeholder *\"[\\]303[\\]244 [\\]303[\\]266\""
)'

test_expect_success "checkout --placeholder handles x-bit." '
    setup_repo xbit && (
        cd xbit &&
        touch x &&
        chmod a+x x &&
        git silo add --attr x &&
        git commit -m "add x" &&
        git silo checkout --placeholder -- x &&
        [ -x x ]
    )
'

# Trick git into creating a placeholder that ends with CRLF by duplicating the
# placeholder file and checking out the duplicate 'b' with autocrlf=true.
# autocrlf has no impact on the original placeholder 'a', because it has the
# gitattribute '-text', which is required by 'git silo'.
test_expect_success \
"git checkout should replace placeholder file even when it contains ends with crlf." '
    git clone repo1 repocrlf && (
        cd repocrlf &&
        git config core.autocrlf true &&
        cp a b &&
        git add b &&
        git commit -m "Add duplicate to get CRLF checkout" &&
        rm b &&
        git checkout b &&
        git silo init &&
        cp b a &&
        git add a &&
        git silo fetch -- . &&
        git silo checkout a &&
        test_cmp ../a a
    )
'

test_expect_success \
"git status should be clean right after git silo checkout." "
    git clone repo1 repo2 && (
        cd repo2 &&
        git silo init &&
        git silo fetch -- . &&
        git silo checkout a &&
        touch ../empty &&
        git status --porcelain >../actual
    ) &&
    test_cmp empty actual
"

test_done
