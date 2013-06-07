#!/bin/bash

test_description="git-silo fetch"

. ./_testinglib.sh

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

PSCP=$(pwd)/pscp.exe
cat >"$PSCP" <<"EOFTXT"
#!/bin/bash

echo "$1" >pscp-arg1
echo "$2" >pscp-arg2
localpath=$(sed -e 's/.*localhost://' <<<"$2")
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
        git-silo fetch -- . &&
        test -e pscp-arg1 &&
        egrep -q 'localhost:[^\"]*[0-9a-f]{38}$' pscp-arg1
    )
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
        git-silo push -- . &&
        test -e pscp-arg2 &&
        egrep -q 'localhost:[^\"]*[0-9a-f]{38}(-tmp)?$' pscp-arg2
    )
"

test_done
