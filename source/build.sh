#!/bin/sh
# Build the runner and leave it where this package can be asked for it.
#
# Swift writes its product deep inside its own build directory, under a path that names the
# toolchain's layout rather than ours. Copying it up to `.build/open-package` gives the
# result one address that does not move when Swift rearranges its own.
set -eu

PACKAGE=source/open-package
BUILD="swift build --package-path $PACKAGE -c release --arch arm64 --arch x86_64"

$BUILD

# Asked for rather than written down. The directory this resolves to is named after the
# toolchain's own layout, and a path spelled here would go on resolving after it stopped
# being where the build writes: the previous one did, and kept installing a binary from an
# earlier build that happened to still be sitting there.
PRODUCT=$($BUILD --show-bin-path)/OpenPackage

[ -f "$PRODUCT" ] || { echo "built, but no product at $PRODUCT" >&2; exit 1; }

mkdir -p .build
install -m 0755 "$PRODUCT" .build/open-package

echo ".build/open-package"
.build/open-package --version
