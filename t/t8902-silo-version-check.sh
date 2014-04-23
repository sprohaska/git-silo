#!/bin/bash

test_description='
Test that silo verifies expectations about environment, e.g. minimal git
version.
'

. ./lib-silo.sh

cat >git <<EOFTXT
#!/bin/bash

echo git version 1.7.0
EOFTXT
chmod a+x git

test_expect_success "setup" '
    git_silo="$(locate_git_silo)" &&
    git init &&
    export PATH=.:$PATH
'

test_expect_success "git silo should fail if git version too low." '
    ! "${git_silo}" init 2>errmsg &&
    grep -q "version too low" errmsg
'

cat >git <<EOFTXT
#!/bin/bash

echo git version 2.0.0
EOFTXT
chmod a+x git

test_expect_success "git silo accept git version 2.x." '
    "${git_silo}" init
'

test_done
