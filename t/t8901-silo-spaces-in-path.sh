#!/bin/bash

test_description='
Test spaces in path to "silo" executable.
'

. ./lib-silo.sh

cp "$(locate_git_silo)" git-silo

test_expect_success \
"'git silo init' should succeed when path to git silo contains spaces." '
    git init &&
    export PATH=.:$PATH &&
    git silo init
'

test_expect_success \
"'git silo add' should succeed when path to git silo contains spaces." '
    export PATH=.:$PATH &&
    touch a &&
    git silo add a 2>stderr &&
    ! grep "error:" stderr
'

test_done
