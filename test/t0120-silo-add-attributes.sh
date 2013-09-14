#!/bin/bash

test_description="git-silo (basic)"

. ./_testinglib.sh

test_expect_success \
"setup user" \
'
    setup_user &&
    setup_repo wildcard
'

test_expect_success \
"git add should not create .gitattributes if wildcard attributes are ok." \
'
    cd wildcard &&
    echo "*.ext -text filter=silo" >.gitattributes &&
    mkdir subdir &&
    touch subdir/a.ext &&
    git-silo add subdir/a.ext &&
    ! [ -e subdir/.gitattributes ]
'

test_done
