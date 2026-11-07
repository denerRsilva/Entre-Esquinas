#!/bin/sh
set -eu
cd "$(dirname "$0")"
target=${1:-linux}
case "$target" in
linux) cc=${CC:-cc}; kind="-fPIC"; output=../bin/librestaurante.so; libs="-lm -lpthread" ;;
windows) cc=${CC:-x86_64-w64-mingw32-gcc}; kind="-static"; output=../bin/restaurante.dll; libs="-lws2_32" ;;
*) exit 2 ;;
esac
$cc -O2 -s -std=gnu11 -D_GNU_SOURCE -shared $kind -Iquickjs ponte.c quickjs/quickjs.c quickjs/dtoa.c quickjs/libregexp.c quickjs/libunicode.c -o "$output" $libs
