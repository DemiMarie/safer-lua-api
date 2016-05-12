#!/bin/sh
set -e
CDPATH=
unset CDPATH
CC=gcc
case $0 in
    (*/*) cd -- "${0%/*}/"
          printf "Entering directory '%s'\n" "${0%/*}/";;
    (*)   : ;;
esac

generated_file=generated.c
#trap 'rm -f -- "$generated_file"' EXIT
lua  -- SafeLuaAPI.lua "$generated_file"
"$CC" "$generated_file" -I. -C -E -std=c11 -D_FORTIFY_SOURCE=1000 > generated.i

shared_flags='-fPIC -fvisibility=hidden -Bsymbolic -Wl,-z,now,-z,relro'

"$CC" "$generated_file" -I. -o bindings.o -Wall -Wextra -Wshadow  \
      -pedantic-errors \
       -g3 -c -fPIC

"$CC" bindings.o -shared -o bindings.so $shared_flags
rm bindings.a -f
ar rs bindings.a bindings.o
