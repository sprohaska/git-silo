. ./sharness/sharness.sh

setup_user() {
    git config --global user.name "A U Thor" &&
    git config --global user.email "author@example.com"
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
