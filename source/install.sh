#!/bin/sh
# Install the open-package runner onto this machine.
#
#   curl -fsSL <base>/source/install.sh | sh
#   curl -fsSL <base>/source/install.sh | sh -s -- --prefix "$HOME/.local/bin"
#
# This is only about getting the runner here. Creating a package is the runner's own job:
# `open-package new <path>`.
set -eu

RUNNER=${OPEN_PACKAGE_RUNNER:-https://github.com/wlsdms0122/open-package/releases/latest/download/open-package}
PREFIX=${OPEN_PACKAGE_PREFIX:-/usr/local/bin}

while [ $# -gt 0 ]; do
  case $1 in
    --prefix) PREFIX=${2:?--prefix needs a directory}; shift 2 ;;
    --prefix=*) PREFIX=${1#--prefix=}; shift ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

command -v curl >/dev/null 2>&1 || { echo "curl is required." >&2; exit 1; }

staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

curl -fsSL "$RUNNER" -o "$staging/open-package" \
  || { echo "could not fetch the runner: $RUNNER" >&2; exit 1; }
chmod +x "$staging/open-package"

# Refuse early rather than half-installing: a partial install leaves a runner that cannot
# say what it is.
"$staging/open-package" --version >/dev/null 2>&1 \
  || { echo "the downloaded runner does not run on this machine." >&2; exit 1; }

mkdir -p "$PREFIX" 2>/dev/null || true
if [ ! -w "$PREFIX" ]; then
  echo "$PREFIX is not writable. Rerun with sudo, or pass --prefix \"\$HOME/.local/bin\"." >&2
  exit 1
fi

install -m 0755 "$staging/open-package" "$PREFIX/open-package"

echo "installed  $PREFIX/open-package"
"$PREFIX/open-package" --version

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo; echo "$PREFIX is not on PATH. Add it to use 'open-package' by name." ;;
esac
