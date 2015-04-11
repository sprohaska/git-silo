#!/bin/bash

test_description='
Test "setminus" implementation.
'

nRuns=1

. ./lib-silo.sh

if ! test_have_prereq UNIX; then
    skip_all="skipping setminus tests on msysgit; 'comm' not available."
    test_done
fi

setminus() {
    { sed <<<"$1" -e 's/^/1 /'; sed <<<"$2" -e 's/^/2 /'; } |
    sort -k 2 --stable | (
        hold=
        while read -r which x; do
            case ${which} in
            1)
                if [ -n "${hold}" ]; then
                    printf '%s\n' "${hold}"
                fi
                hold=${x}
                ;;
            2)
                if [ -n "${hold}" ] && [ "${hold}" != "${x}" ]; then
                    printf '%s\n' "${hold}"
                fi
                hold=
                ;;
            esac
        done
        if [ -n "${hold}" ]; then
            printf '%s\n' "${hold}"
        fi
    )
}

runTest() {
    n=$1
    test_expect_success "setminus (n=${n})" '
        rm -f a b &&
        for ((i=0; i < $n; i++)); do
            sha1=$(head -c 10 /dev/urandom | openssl sha1) &&
            echo ${sha1} >>a
            if [ ${RANDOM} -gt 10000 ]; then
                echo ${sha1} >>b
            fi
        done &&
        setminus "$(cat a)" "$(cat b)" >setminus.out &&
        sort a >a.sorted &&
        sort b >b.sorted &&
        comm -23 a.sorted b.sorted >comm.out &&
        test_cmp setminus.out comm.out
    '
}

for x in $(seq 1 ${nRuns}); do
    runTest 10
    runTest 50
    runTest 100
    runTest 1000
done

test_done
