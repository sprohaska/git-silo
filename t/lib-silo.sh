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

if ( git update-index -h 2>&1 || true ) | grep -q assume-unchanged-once; then
    test_set_prereq ASSUME_UNCHANGED_ONCE
fi

case $(uname) in
    MINGW*)
        test_set_prereq WINDOWS
        ;;
    *)
        test_set_prereq UNIX
        ;;
esac

case $(uname) in
SunOS)
    sort() {
        gsort "$@"
    }
    sed() {
        gsed "$@"
    }
    find() {
        gfind "$@"
    }
    grep() {
        /usr/xpg4/bin/grep "$@"
    }
    egrep() {
        /usr/xpg4/bin/egrep "$@"
    }
esac

setup_user() {
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
}

setup_file() {
    local f="$1"
    echo "${f}" >"${f}" &&
    ( openssl sha1 "${f}" | cut -d '=' -f 2 | sed -e 's/^ *//' > "${f}.sha1" )
}

setup_repo() {
    local repo=$1
    shift
    mkdir $repo &&
    (
        cd $repo &&
        git init "$@" &&
        git silo init &&
        touch .gitignore &&
        git add .gitignore &&
        git commit -m 'initial commit'
    )
}

setup_add_file() {
    local repo="$1"
    local file="$2"
    (
        cd $repo &&
        cp "../${file}" "${file}" &&
        git silo add --attr "${file}" &&
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

locate_git_silo() {
    local p
    p="$(git --exec-path)"/git-silo
    if ! [ -x "${p}" ]; then
        p=$(which git-silo) || return 1
    fi
    echo "${p}"
}

assertRepoHasSiloObject() {
    local repo=$1
    local file=$2
    local obj
    obj="$(cat "${file}.sha1")"
    obj="${obj:0:2}/${obj:2}"
    [ -f "${repo}/.git/silo/objects/${obj}" ] && return 0
    say_color error "Assert failed: missing object ${obj} (${file}) in repo '${repo}'."
    return 1
}

siloObjectPath() {
    local repo=$1
    local file=$2
    local obj
    obj="$(cat "${file}.sha1")"
    obj="${obj:0:2}/${obj:2}"
    echo "${repo}/.git/silo/objects/${obj}"
}

assertRepoHasNumSiloObjects() {
    local repo=$1
    local expected=$2
    local actual
    actual=$(find "${repo}/.git/silo/objects" -type f | wc -l | sed -e 's/ *//g')
    (( $expected == $actual )) && return 0
    say_color error "Assert failed: wrong number of silo objects in repo '${repo}', expected ${expected}, actual ${actual}."
    return 1
}
