#!/bin/bash

test_description='
Test packing (WIP)
'

. ./lib-silo.sh

if ! type 7zr >/dev/null 2>&1; then
    skip_all='Skipping tests, because 7zr is not available.'
    test_done
fi

assertNumObjects() {
    assertNumFilesIn '.git/silo/objects' $1
}

assertNumPacks() {
    assertNumFilesIn '.git/silo/packs' $1
}

assertNumFilesIn() {
    local dir=$1
    local expected=$2
    local actual=$(numFilesIn "${dir}")
    [ $expected == $actual ] && return 0
    error "Wrong number of files in '${dir}': expected ${expected}, actual ${actual}."
}

numFilesIn() {
    find "$1" -type f |
    wc -l |
    sed -e 's/ *//g'
}

cat >7zr <<\EOF
#!/bin/bash

echo "invalid"
EOF

chmod a+x 7zr
cp 7zr 7z

test_expect_success 'setup' '
    setup_user &&
    setup_repo repo &&
    ( cd repo && git config silo.packSizeLimit 8K )
'

test_expect_success 'unpack should handle empty silo' '(
    cd repo &&
    git silo unpack 2>err &&
    [ -z "$(cat err)" ]
)'

test_expect_success 'pack should handle empty silo' '(
    cd repo &&
    git silo pack
)'

test_expect_success 'pack and unpack should report missing 7z.' '(
    cd repo &&
    export PATH=..:$PATH &&
    ! git silo pack 2>err &&
    grep -qi "missing.*7z" err &&
    ! git silo unpack 2>err &&
    grep -qi "missing.*7z" err
)'

test_expect_success 'setup files (1..5)' '(
    cd repo &&
    for i in $(seq 1 5); do
        printf "%${i}024d" $i >$i &&
        git silo add $i ||
        error "failed to setup file $i."
    done &&
    git commit -m "add files"
)'

test_expect_success 'pack should create expected number of packs.' '(
    cd repo &&
    git silo pack &&
    assertNumPacks 3
)'

test_expect_success "'pack --keep' should keep loose objects." '(
    cd repo &&
    git silo pack --keep &&
    assertNumObjects 5
)'

test_expect_success "'pack --prune' should remove loose objects." '(
    cd repo &&
    git silo pack --prune &&
    assertNumObjects 0
)'

test_expect_success "'unpack 1' should create one loose object." '(
    cd repo &&
    git silo unpack 1 &&
    assertNumObjects 1
)'

test_expect_success "'unpack --prune-packs 1' should keep packs." '(
    cd repo &&
    git silo unpack --prune-packs 1 &&
    assertNumPacks 3
)'

test_expect_success "'unpack' should create all 5 loose object." '(
    cd repo &&
    git silo unpack &&
    assertNumObjects 5
)'

test_expect_success "'unpack --keep-packs' should keep packs." '(
    cd repo &&
    git silo unpack --keep-packs &&
    assertNumPacks 3
)'

test_expect_success "'unpack --prune-packs' should remove packs." '(
    cd repo &&
    git silo unpack --prune-packs &&
    assertNumPacks 0
)'

test_expect_success "setup shared repo." '
    setup_repo sharedrepo --shared &&
    setup_file a &&
    setup_add_file sharedrepo a
'

test_expect_success "'unpack' should maintain shared permissions." '(
    cd sharedrepo &&
    git silo pack --prune &&
    git silo unpack &&
    isSharedDir .git/silo/objects/$(cut -b 1-2 ../a.sha1)
)'

test_expect_success 'setup files (6..10)' '(
    cd repo &&
    for i in $(seq 6 10); do
        printf "%${i}024d" $i >$i &&
        git silo add $i ||
        error "failed to setup file $i."
    done &&
    git commit -m "add files"
)'

test_expect_success 'pack should succeed.' '(
    cd repo &&
    git silo pack &&
    assertNumPacks 6
)'

test_expect_success 'setup files (11..99)' '(
    cd repo &&
    for i in $(seq 11 99); do
        printf "%3${i}0d" $i >$i &&
        git silo add $i ||
        error "failed to setup file $i."
    done &&
    git commit -m "add files"
)'

test_expect_success "'pack --prune' should keep 2 (large) loose objects." '(
    cd repo &&
    git silo pack --prune &&
    assertNumObjects 2 &&
    assertNumPacks 69
)'

test_expect_success "'unpack' should create all loose object." '(
    cd repo &&
    git silo unpack &&
    assertNumObjects 99
)'

test_expect_success "'unpack' should create loose objects for HEAD." '(
    cd repo &&
    git rm 9? &&
    git commit -m "remove 9?" &&
    git silo pack --prune &&
    assertNumObjects 2 &&
    git silo unpack &&
    assertNumObjects 89
)'

test_expect_success "'unpack --prune-packs' should keep a few packs." '(
    cd repo &&
    git silo unpack --prune-packs &&
    assertNumPacks 10
)'

test_expect_success \
"'unpack --all --prune-packs' should unpack and prune all." '(
    cd repo &&
    git silo unpack --all --prune-packs &&
    assertNumObjects 99 &&
    assertNumPacks 0
)'

test_expect_success \
"'pack' creates a single pack when packSizeLimit=0." '(
    cd repo &&
    git config silo.packSizeLimit 0 &&
    git silo pack &&
    assertNumPacks 1
)'

test_done
