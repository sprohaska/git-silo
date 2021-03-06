#!/bin/bash

test_description='
Test basic garbage collection.
'

. ./lib-silo.sh

nl=$'\n'

test_expect_success "setup user" '
    setup_user
'

test_expect_success "setup repo" "
    git init &&
    git config core.autocrlf false &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m 'initial commit' &&
    git silo init
"

test_expect_success "'git silo gc' should succeed with empty silo." '
    git silo gc
'

test_expect_success "setup add files" "
    setup_file a &&
    setup_file b &&
    setup_file c &&
    ( cat a.sha1 b.sha1 | sort -u >ab.sha1 ) &&
    ( cat b.sha1 c.sha1 | sort -u >bc.sha1 ) &&
    ( cat a.sha1 b.sha1 c.sha1 | sort -u >abc.sha1 )
"

test_expect_success "'git silo add' should add objects to silo store." "
    git checkout -b tmp &&
    git silo add --attr c &&
    git commit -m 'Add c' &&
    git checkout master &&
    git silo add --attr a b &&
    git commit -m 'Add a, b' &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success "'git silo gc' should keep all reachable objects." "
    git tag witha &&
    git rm a &&
    git commit -m 'Remove a' &&
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success "'git silo gc --dry-run' should not delete anything." "
    git branch -D tmp &&
    git silo gc --dry-run &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp abc.sha1 actual
"

test_expect_success \
"'git silo gc --dry-run' should report objects that would be deleted." '
    git silo gc --dry-run | egrep -i "would remove.*[0-9a-f/]{41}"
'

test_expect_success \
"'git silo gc' should collect objects that are unreachable..." '
    git silo gc &&
    ( cd .git/silo/objects && find * -type f | sed -e "s@/@@" ) >actual &&
    test_cmp ab.sha1 actual
'
test_expect_success \
"... and remove empty directories." '
    [ "$(find .git/silo/objects -type d -empty -mindepth 1 -maxdepth 1)" == "" ]
'

test_expect_success \
"'git silo gc -n 1' should keep latest objects reachable by tag." "
    git silo gc -n 1 &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp ab.sha1 actual
"

test_expect_success \
"'git silo gc -n 1 --no-tags' should remove latest objects reachable only by tag." "
    git silo gc -n 1 --no-tags &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp b.sha1 actual
"

test_expect_success \
"'git silo gc -n 1' should keep only latest objects." "
    git tag -d witha &&
    echo a >a &&
    git silo add --attr a &&
    git commit -m 'Add a' &&
    git rm a &&
    git commit -m 'Remove a' &&
    git silo gc -n 1 &&
    ( cd .git/silo/objects && find * -type f | sed -e 's@/@@' ) >actual &&
    test_cmp b.sha1 actual
"

test_expect_success \
"'git silo' without '--gitattributes' should leave .gitattributes alone." '
    echo a >a &&
    git silo add --attr a &&
    git commit -m "Add a" &&
    git rm a &&
    git commit -m "Remove a" &&
    cp .gitattributes expected &&
    git silo gc &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git silo --gitattributes' should clean up .gitattributes" '
    grep ^/b .gitattributes >expected &&
    git silo gc --gitattributes &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git silo --gitattributes --dry-run' should not report cleanup of .gitattributes if unchanged." '
    ! ( git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes" )
'

test_expect_success \
"'git silo --gitattributes --dry-run' should report planned cleanup but leave .gitattributes alone." '
    git checkout HEAD^ -- .gitattributes &&
    git commit -m "Reset gitattributes" &&
    cp .gitattributes expected &&
    ( git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes" ) &&
    test_cmp expected .gitattributes
'

test_expect_success \
"'git silo --gitattributes --dry-run' should report cleanup of .gitattributes." '
    git silo gc --gitattributes --dry-run | grep "Would clean.*gitattributes"
'

test_expect_success 'gc should handle subdir with spaces' '
    mkdir "s d" &&
    echo a >"s d/a" &&
    echo b >"s d/b" &&
    git silo add --attr "s d/a" &&
    cp "s d/.gitattributes" expected &&
    git silo add --attr "s d/b" &&
    git commit -m "add a b" &&
    git rm "s d/b" &&
    git commit -m "rm b" &&
    git silo gc --gitattributes &&
    test_cmp expected "s d/.gitattributes"
'

test_expect_success 'gc robustly handles symlinks and placeholder lookalikes.' '
    setup_repo lookalikes && (
        cd lookalikes &&
        echo "symlink* filter=silo -text" >>.gitattributes &&
        echo "silocontent* filter=silo -text" >>.gitattributes &&
        git add -- .gitattributes &&
        ln -s "../../../../invalid/path/of/length/41___${nl}" "symlink 1" &&
        ln -s "../../../../invalid/path/of/length/41____" "symlink 2" &&
        ln -s "../../../../invalid/path/of/length/41____" "symlink 3" &&
        git silo add -- "symlink 1" "symlink 2" "symlink 3" &&
        printf "xxx1af1af1af1af1af1af1af1af1af1af1af1af0${nl}" >"content 1" &&
        printf "1af${nl}00${nl}00${nl}1af001af1af1af1af1af1af1af1af00" >"content 2" &&
        printf "1af1af1af${nl}1af1af00${nl}1af0${nl}1af00${nl}1af1af1af00" >"content 3" &&
        git add -- "content 1" "content 2" "content 3" &&
        printf "xxx1af1af1af1af1af1af1af1af1af1af1af1af0${nl}" >"silocontent 1" &&
        printf "1af${nl}00${nl}00${nl}1af001af1af1af1af1af1af1af1af00" >"silocontent 2" &&
        printf "1af1af1af${nl}1af1af00${nl}1af0${nl}1af00${nl}1af1af1af00" >"silocontent 3" &&
        git silo add -- "silocontent 1" "silocontent 2" "silocontent 3" &&
        git commit -m content &&
        find .git/silo/objects -type f >../before &&
        git silo gc -n 1 &&
        find .git/silo/objects -type f >../after &&
        test_cmp ../before ../after
    )
'

test_done
