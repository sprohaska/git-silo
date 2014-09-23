#!/bin/bash

test_description='
Test automatic unpack
'

. ./lib-silo.sh

if ! type 7zr >/dev/null 2>&1; then
    skip_all='Skipping tests, because 7zr is not available.'
    test_done
fi

ssh localhost true 2>/dev/null && test_set_prereq LOCALHOST

cat >7zr <<\EOF
#!/bin/bash

echo "invalid"
EOF

chmod a+x 7zr
cp 7zr 7z

test_expect_success "setup" '
    setup_user &&
    setup_file first &&
    setup_file second &&
    setup_repo orig &&
    setup_add_file orig first &&
    setup_add_file orig second
'

test_expect_success "setup (pack)" '(
    cd orig &&
    git silo pack &&
    git config silo.autounpack true
)'

test_expect_success "'silo fetch' (cp) should ignore invalid 7z" '
    git clone orig cpclone1 && (
        cd cpclone1 &&
        git silo init &&
        export PATH=$(cd ..; pwd):$PATH &&
        git silo fetch -- .
    ) &&
    assertRepoHasSiloObject cpclone1 first &&
    assertRepoHasSiloObject cpclone1 second
'

test_expect_success "setup (prune)" '(
    cd orig &&
    git silo pack --prune --all
)'

test_expect_success "'silo fetch' (cp) should autounpack" '
    git clone orig cpclone && (
        cd cpclone &&
        git silo init &&
        git silo fetch -- .
    ) &&
    assertRepoHasSiloObject cpclone first &&
    assertRepoHasSiloObject cpclone second
'

ssh_tests_with_transport() {
local transport="$1"

test_expect_success "setup (prune)" '(
    cd orig &&
    git silo pack --prune --all
)'

test_expect_success "setup sshclone (${transport})" "
    rm -rf sshclone &&
    setup_clone_ssh orig sshclone && (
        cd sshclone &&
        git silo init &&
        git config silo.sshtransport ${transport}
    )
"

test_expect_success \
"'silo fetch' (${transport}) should fetch" '(
        cd sshclone &&
        git silo fetch -- .
    ) &&
    assertRepoHasSiloObject sshclone first &&
    assertRepoHasSiloObject sshclone second
'

}  # ssh_tests_with_transport

if ! test_have_prereq LOCALHOST; then
    skip_all='skipping tests that require ssh to localhost.'
    test_done
fi

ssh_tests_with_transport sshcat

test_done
