#!/bin/bash

test_description="git-silo gc"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user
'

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
"'git-silo add' should add objects to silo store." \
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
"'git-silo gc' should keep all reachable objects." \
"
    git tag witha &&
    git rm a &&
    git commit -m 'Remove a' &&
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success \
"'git-silo gc --dry-run' should not delete anything." \
"
    git branch -D tmp &&
    git silo gc --dry-run &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success \
"'git-silo gc --dry-run' should report objects that would be deleted." \
'
    git silo gc --dry-run | egrep ^[0-9a-f/]{41}
'

test_expect_success \
"'git-silo gc' should collect objects that are unreachable." \
"
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp ab.sha1 actual
"

test_expect_success \
"'git-silo gc -n 1' should keep latest objects reachable by tag." \
"
    git silo gc -n 1 &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp ab.sha1 actual
"

test_expect_success \
"'git-silo gc -n 1 --no-tags' should remove latest objects reachable only by tag." \
"
    git silo gc -n 1 --no-tags &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp b.sha1 actual
"

test_expect_success \
"'git-silo gc -n 1' should keep only latest objects." \
"
    git tag -d witha &&
    echo a >a &&
    git-silo add a &&
    git commit -m 'Add a' &&
    git rm a &&
    git commit -m 'Remove a' &&
    git silo gc -n 1 &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp b.sha1 actual
"

test_expect_success \
"'git-silo' without '--gitattributes' should leave .gitattributes alone." \
'
    echo a >a &&
    git-silo add a &&
    git commit -m "Add a" &&
    git rm a &&
    git commit -m "Remove a" &&
    cp .gitattributes expected &&
    git silo gc &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git-silo --gitattributes' should clean up .gitattributes" \
'
    grep ^/b .gitattributes >expected &&
    git silo gc --gitattributes &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git-silo --gitattributes --dry-run' should not report cleanup of .gitattributes if unchanged." \
'
    ! ( git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes" )
'

test_expect_success \
"'git-silo --gitattributes --dry-run' should report planned cleanup but leave .gitattributes alone." \
'
    git checkout HEAD^ -- .gitattributes &&
    git commit -m "Reset gitattributes" &&
    cp .gitattributes expected &&
    ( git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes" ) &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git-silo --gitattributes --dry-run' should report cleanup of .gitattributes." \
'
    git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes"
'

test_done
