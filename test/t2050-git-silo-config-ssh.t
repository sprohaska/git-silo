#!/bin/bash

test_description="git-silo fetch"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

PSCP=$(pwd)/pscp.exe
cat >"$PSCP" <<"EOFTXT"
#!/bin/bash

[ "$1" = "-batch" ] || {
    echo "Error: pscp wasn't called with first arg -batch." >&2
    exit 1
}
echo "$2" >"$(dirname "$0")/pscp-arg1"
echo "$3" >"$(dirname "$0")/pscp-arg2"
localpath=$(sed -e 's/.*localhost://' <<<"$3")
touch "$localpath"
EOFTXT
chmod a+x "$PSCP"

test_expect_success \
"setup" \
'
    setup_user &&
    setup_file first &&
    setup_file second &&
    setup_repo origrepo &&
    setup_add_file origrepo first
'

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

test_expect_success \
"'git-silo fetch' (scp) should use custom pscp when specified and call it without double quotes" \
"
    setup_clone_ssh origrepo clonefetch &&
    (
        cd clonefetch &&
        git-silo init &&
        git config silo.scp '$PSCP' &&
        git-silo fetch -- .
    ) &&
    test -e pscp-arg1 &&
    egrep -q 'localhost:[^\"]*[0-9a-f]{38}$' pscp-arg1
"

test_expect_success \
"'git-silo push' (scp) should use custom pscp when specified and call it without double quotes" \
"
    setup_clone_ssh origrepo clonepush &&
    ( cd clonepush && git-silo init ) &&
    setup_add_file clonepush second &&
    (
        cd clonepush &&
        git config silo.scp '$PSCP' &&
        git-silo push -- .
    ) &&
    test -e pscp-arg2 &&
    egrep -q 'localhost:[^\"]*[0-9a-f]{38}(-tmp)?$' pscp-arg2
"


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
"'git-silo fetch' (scp) should use custom plink from GIT_SSH." \
"
    (
        cd clonefetch &&
        git-silo init &&
        rm -f plink-called &&
        git-silo fetch -- . &&
        test -e plink-called
    )
"

test_expect_success \
"'git-silo push' (scp) should use custom plink from GIT_SSH." \
"
    (
        cd clonepush &&
        rm -f plink-called &&
        git-silo push -- . &&
        test -e plink-called
    )
"

test_done
