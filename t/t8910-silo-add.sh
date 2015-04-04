#!/bin/bash

test_description='
Test basic "silo add" operations.
'

. ./lib-silo.sh

test_expect_success "setup user" '
    setup_user
'

test_expect_success "'git silo add' should handle paths with spaces." '
    git init &&
    touch .gitignore &&
    git add .gitignore &&
    git commit -m "initial commit" &&
    git silo init &&
    echo a >"a a" &&
    git silo add --attr "a a" &&
    git commit -m "Add a a" &&
    ( test $(blobSize "a a") -eq 41 || ( echo "Wrong blob size." && false ) )
'

test_expect_success \
"'git checkout' of silo content should handle paths with spaces." '
    rm "a a" &&
    git checkout "a a" &&
    test -e "a a"
'

test_expect_success "'git silo checkout' should handle paths with spaces." '
    rm "a a" &&
    git silo checkout "a a" &&
    test -e "a a"
'

test_expect_success \
"'add' updates committed files." '
    git silo checkout --copy "a a" &&
    echo a >>"a a" &&
    git silo add -- "a a" &&
    ( git status --porcelain -- "a a" | grep ^M )
'

test_expect_success "'add' remove file." '
    rm "a a" &&
    git silo add -- "a a" 2>err &&
    touch empty &&
    test_cmp empty err &&
    ( git status --porcelain | grep -q "^D  .a a." )
'

test_expect_success "'add' should handle deleted file twice." '
    git silo add -- "a a" 2>err &&
    test_cmp empty err
'

nl=$'\n'

# Create multiple symlinks to ensure that lsSiloTracked() sees multiple
# entries.  Use newline in the first symlink so that it closely resembles a
# sha1 placeholder.
test_expect_success "'add' handles symlinks that look like sha1s." '
    echo "symlink* filter=silo -text" >>.gitattributes &&
    ln -s "../../../../invalid/path/of/length/41___${nl}" "symlink 1" &&
    ln -s "../../../../invalid/path/of/length/41____" "symlink 2" &&
    ln -s "../../../../invalid/path/of/length/41____" "symlink 3" &&
    git silo add -- "symlink 1" "symlink 2" "symlink 3" 2>err &&
    touch empty &&
    test_cmp empty err &&
    git commit -m "symlinks" &&
    rm -f "symlink 1" "symlink 2" "symlink 3" &&
    git silo checkout -- . &&
    ! [ -e "symlink 1" ] &&
    ! [ -e "symlink 2" ] &&
    ! [ -e "symlink 3" ]
'


test_expect_success "'add' handles content that resembles a placeholder." '
    touch empty &&
    echo "silocontent* filter=silo -text" >>.gitattributes &&
    printf "xxx1af1af1af1af1af1af1af1af1af1af1af1af0${nl}" >"content 1" &&
    printf "1af${nl}00${nl}00${nl}1af0${nl}1af1af1af1af1af1af1af1af00" >"content 2" &&
    printf "1af1af1af${nl}1af1af00${nl}1af0${nl}1af00${nl}1af1af1af00" >"content 3" &&
    git add -- "content 1" "content 2" "content 3" 2>err &&
    test_cmp empty err &&
    printf "xxx1af1af1af1af1af1af1af1af1af1af1af1af0${nl}" >"silocontent 1" &&
    printf "1af${nl}00${nl}00${nl}1af0${nl}1af1af1af1af1af1af1af1af00" >"silocontent 2" &&
    printf "1af1af1af${nl}1af1af00${nl}1af0${nl}1af00${nl}1af1af1af00" >"silocontent 3" &&
    git silo add -- "silocontent 1" "silocontent 2" "silocontent 3" 2>err &&
    git commit -m "content" &&
    rm -f "content 1" "content 2" "content 3" &&
    rm -f "silocontent 1" "silocontent 2" "silocontent 3" &&
    git silo checkout -- . &&
    [ -f "silocontent 1" ] &&
    [ -f "silocontent 2" ] &&
    [ -f "silocontent 3" ] &&
    ! [ -e "content 1" ] &&
    ! [ -e "content 2" ] &&
    ! [ -e "content 3" ]
'


test_done
