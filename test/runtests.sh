#!/bin/bash

cd $(dirname "$0")
err=
for t in t????-*.t; do
    echo
    echo "# $t"
    ./$t || err=t
done

echo
if test $err; then
    echo "FAIL (some tests failed; see errors above)"
else
    echo "OK (all tests passed)"
fi
