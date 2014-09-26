#!/bin/bash

test_description='
Test support for wildcard gitattributes.
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user &&
    setup_repo wildcard
'

test_expect_success \
"'add --attr' does not create .gitattributes if wildcard attributes are ok." '(
    cd wildcard &&
    echo "*.ext -text filter=silo" >.gitattributes &&
    mkdir subdir &&
    touch "subdir/a a.ext" &&
    git silo add --attr "subdir/a a.ext" &&
    ! [ -e subdir/.gitattributes ]
)'

test_expect_success \
"'add --no-attr' does not add file without filter=silo attribute but exits with success." '(
    cd wildcard &&
    touch "subdir/b b" &&
    git silo add --no-attr "subdir/b b" 2>err &&
    ( git status --porcelain -- "subdir/b b" | grep "^??" ) &&
    grep "missing.*filter=silo" err
)'

test_expect_success \
"'add --attr' adds file and modifies gitattributes." '(
    cd wildcard &&
    touch "subdir/b b" &&
    git silo add --attr "subdir/b b" 2>err &&
    ( git status --porcelain -- "subdir/b b" | grep "^A" ) &&
    [ -e subdir/.gitattributes ]
)'

test_expect_success \
"'add --no-attr' adds file with filter=silo attribute." '(
    cd wildcard &&
    touch "subdir/c c.ext" &&
    git silo add --no-attr "subdir/c c.ext" 2>err &&
    ( git status --porcelain -- "subdir/c c.ext" | grep ^A )
)'

test_done
