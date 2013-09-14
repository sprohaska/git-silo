#!/bin/bash

test_description="git-silo dependencies"

. ./_testinglib.sh

cat >git <<EOFTXT
#!/bin/bash

echo git version 1.7.0
EOFTXT
chmod a+x git

test_expect_success \
"git-silo should fail if git version too low." \
'
    git init
    export PATH=.:$PATH
    ! git-silo init 2>errmsg &&
    grep -q "version too low" errmsg
'

test_done
