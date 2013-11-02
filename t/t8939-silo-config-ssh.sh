#!/bin/bash

test_description='
Test that ssh operations can be configured.  In particular, test that PuTTy is
supported.
'

. ./lib-silo.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_file second &&
    setup_repo origrepo &&
    setup_add_file origrepo first
'

PLINK=$(pwd)/plink.exe
cat >"$PLINK" <<"EOFTXT"
#!/bin/bash

[ "$1" = "-batch" ] || {
    echo "Error: plink wasn't called with first arg -batch." >&2
    exit 1
}
shift

touch plink-called

ssh "$@"
EOFTXT
chmod a+x "$PLINK"
export GIT_SSH=$PLINK

test_expect_success \
"'silo fetch' (ssh) should use custom plink from GIT_SSH." "
    setup_clone_ssh origrepo clonefetch && (
        cd clonefetch &&
        git silo init &&
        rm -f plink-called &&
        git silo fetch -- . &&
        test -e plink-called
    )
"

test_expect_success \
"'silo push' (ssh) should use custom plink from GIT_SSH." "
    setup_clone_ssh origrepo clonepush && (
        cd clonepush &&
        git silo init &&
        rm -f plink-called &&
        git silo push -- . &&
        test -e plink-called
    )
"

test_done
