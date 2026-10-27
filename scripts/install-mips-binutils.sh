#!/usr/bin/env bash
set -euo pipefail

BINUTILS_VERSION="${BINUTILS_VERSION:-binutils-2_44}"
BINUTILS_PREFIX="${BINUTILS_PREFIX:-$HOME/.local/opt/binutils-mips}"
TARGET="${TARGET:-mips64el-none-elf}"
BUILD_JOBS="${BUILD_JOBS:-$(nproc)}"

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script currently supports Debian/Ubuntu systems with apt-get." >&2
    exit 1
fi

apt_packages=(gcc clang make texinfo libmpc-dev bison flex git)
if [[ "$(id -u)" -eq 0 ]]; then
    apt_get=(apt-get)
elif command -v sudo >/dev/null 2>&1; then
    apt_get=(sudo apt-get)
else
    echo "Installing build dependencies requires root or sudo access." >&2
    exit 1
fi

"${apt_get[@]}" update
"${apt_get[@]}" install -y "${apt_packages[@]}"

build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

git clone --depth 1 --branch "$BINUTILS_VERSION" \
    https://sourceware.org/git/binutils-gdb.git "$build_dir/binutils-gdb"
mkdir "$build_dir/build"
cd "$build_dir/build"

"$build_dir/binutils-gdb/configure" \
    --target="$TARGET" \
    --prefix="$BINUTILS_PREFIX"
make configure-host
make -j"$BUILD_JOBS"
make install

echo
echo "Installed $TARGET binutils to $BINUTILS_PREFIX/bin"
echo "Add this to your shell configuration to use it:"
echo "  export PATH=\"$BINUTILS_PREFIX/bin:\$PATH\""
