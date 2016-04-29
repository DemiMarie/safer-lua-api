#!/bin/sh
set -e
CDPATH=
unset CDPATH
case $0 in
    (*/*) cd -- "${0%/*}/"
          printf "Entering directory '%s'\n" "${0%/*}/";;
    (*)   : ;;
esac
lua SafeLuaAPI.lua generated.c
clang generated.c -C -E -w -std=c11 -D_FORTIFY_SOURCE=1000 |
    clang-format > generated.i

shared_flags='-fPIC -fvisibility=hidden -Bsymbolic -Wl,-z,now,-z,relro'

clang generated.i -lluajit-5.1 -o bindings.o -w -pedantic-errors \
      -ferror-limit=1000 -g3 -c $shared_flags

clang bindings.o -shared -o bindings.so $shared_flags
rm bindings.a -f
ar rs bindings.a bindings.o
