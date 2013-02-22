#!/bin/bash

test_description="git-silo (basic)"

. ./sharness/sharness.sh

test_expect_success \
"Setup" \
"
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m 'initial commit' &&
    git-silo init
    echo a >a &&
    ( openssl sha1 a | cut -d ' ' -f 2 > a.sha1 ) &&
    echo b >b &&
    ( openssl sha1 b | cut -d ' ' -f 2 > b.sha1 ) &&
    echo c >c &&
    ( openssl sha1 c | cut -d ' ' -f 2 > c.sha1 ) &&
    ( cat a.sha1 b.sha1 | sort -u >ab.sha1 ) &&
    ( cat b.sha1 c.sha1 | sort -u >bc.sha1 ) &&
    ( cat a.sha1 b.sha1 c.sha1 | sort -u >abc.sha1 )
"

test_expect_success \
"'git-silo add' will add objects to silo store." \
"
    git checkout -b tmp &&
    git-silo add c &&
    git commit -m 'Add c' &&
    git checkout master &&
    git-silo add a b &&
    git commit -m 'Add a, b' &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success \
"'git-silo gc' will collect objects that are not part of current heads." \
"
    git rm a &&
    git commit -m 'Remove a' &&
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp bc.sha1 actual
"

test_expect_success \
"'git-silo gc' will collect objects of deleted branch." \
"
    git branch -D tmp &&
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp b.sha1 actual
"

test_done
