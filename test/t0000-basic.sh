describe "git-silo"

before() {
    sandbox=$(pwd)/sandbox
    rm -rf $sandbox
    mkdir -p $sandbox
    cd $sandbox
}

after() {
    rm -rf "$sandbox"
}

it_will_init_silo() {
    git init
    git-silo init
}
