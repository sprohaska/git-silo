sharness=./sharness/sharness.sh
gittestlib=./test-lib.sh

if [ -e ${gittestlib} ]; then
    TEST_NO_CREATE_REPO=NoThanks
    . ${gittestlib}
elif [ -e ${sharness} ]; then
    . ${sharness}
else
    echo >&2 "Error: Could neither find sharness nor git's test-lib.sh."
    exit 1
fi

case $(uname) in
    MINGW*)
        test_set_prereq WINDOWS
        ;;
    *)
        test_set_prereq UNIX
        ;;
esac

setup_user() {
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
}

setup_file() {
    local f=$1
    echo $f >$f &&
    ( openssl sha1 $f | cut -d ' ' -f 2 > $f.sha1 )
}

setup_repo() {
    local repo=$1
    shift
    mkdir $repo &&
    (
        cd $repo &&
        git init "$@" &&
        git-silo init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m 'initial commit'
    )
}

setup_add_file() {
    local repo=$1
    local file=$2
    (
        cd $repo &&
        cp ../$file $file &&
        git-silo add $file &&
        git commit -m "Add $file"
    )
}

setup_clone_ssh() {
    local repo1=$1
    local repo2=$2
    git clone "ssh://localhost$(pwd)/$repo1" "$repo2"
}

blobSize() {
    git ls-tree -rl HEAD -- "$1" |
    cut -f 1 |
    sed -e 's/  */ /g' |
    cut -d ' ' -f 4
}

isSharedDir() {
    test -g "$1"
}

linkCount() {
    ls -l $1 | sed -e 's/  */ /' | cut -d ' ' -f 2
}
