#!/bin/sh
set -eu
cd "$(dirname "$0")"
target=${1:-linux}
case "$target" in
linux) cc=${CC:-cc}; kind="-fPIC"; output=../bin/librestaurante.so; libs="-lm -lpthread" ;;
windows) cc=${CC:-x86_64-w64-mingw32-gcc}; kind="-static"; output=../bin/restaurante.dll; libs="-lws2_32" ;;
android)
    : "${ANDROID_NDK_ROOT:?Defina ANDROID_NDK_ROOT para o NDK Android}"
    abi=${2:-arm64-v8a}
    case "$abi" in
        arm64-v8a) triple=aarch64-linux-android ;;
        armeabi-v7a) triple=armv7a-linux-androideabi ;;
        x86_64) triple=x86_64-linux-android ;;
        *) echo "ABI Android inválida: $abi" >&2; exit 2 ;;
    esac
    cc="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/${triple}23-clang"
    kind="-fPIC -Wl,-z,max-page-size=16384"
    mkdir -p "../bin/android/$abi"
    output="../bin/android/$abi/librestaurante.so"
    libs="-lm"
    ;;
*) exit 2 ;;
esac
$cc -O2 -s -std=gnu11 -D_GNU_SOURCE -shared $kind -Iquickjs ponte.c quickjs/quickjs.c quickjs/dtoa.c quickjs/libregexp.c quickjs/libunicode.c -o "$output" $libs
