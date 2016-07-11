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
set +e
generator='Unix Makefiles'
while getopts G: arg; do
  case $arg in
    (G) generator=$OPTARG;;
    (\-) # End of options
        break 2;;
    (:) eval 'printf "Missing argument to option '\'%s\''\\n" "$'$OPTIND\"; exit 1;;
  esac
done
shift $OPTIND
set -e
mkdir -p build
cd build
cmake -G "$generator" ..
cmake --build . --clean-first
