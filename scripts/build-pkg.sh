#!/bin/bash
set -eo pipefail

ARCH="$1"
BIN_PATH="$2"
PKG_VERSION="$3"
PKG_RELEASE="${4:-1}"
OUTPUT_DIR="${5:-dist}"

if [ -z "$ARCH" ] || [ -z "$BIN_PATH" ] || [ -z "$PKG_VERSION" ]; then
    echo "Usage: $0 <arch> <bin_path> <version> [release] [output_dir]"
    echo "Example: $0 aarch64_cortex-a53 ./sing-box 1.14.4 1 dist"
    exit 1
fi

if [ ! -f "$BIN_PATH" ]; then
    echo "Error: Binary not found at $BIN_PATH"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "$STAGING_DIR"' EXIT

echo "==> Staging files for sing-box-tiny ($ARCH)..."
mkdir -p "$STAGING_DIR/usr/bin"
mkdir -p "$STAGING_DIR/etc/init.d"
mkdir -p "$STAGING_DIR/etc/config"
mkdir -p "$STAGING_DIR/etc/sing-box"
mkdir -p "$STAGING_DIR/usr/share/sing-box"

cp "$BIN_PATH" "$STAGING_DIR/usr/bin/sing-box"
chmod 755 "$STAGING_DIR/usr/bin/sing-box"

cp "$REPO_DIR/files/sing-box.init" "$STAGING_DIR/etc/init.d/sing-box"
chmod 755 "$STAGING_DIR/etc/init.d/sing-box"

cp "$REPO_DIR/files/sing-box.conf" "$STAGING_DIR/etc/config/sing-box"
chmod 644 "$STAGING_DIR/etc/config/sing-box"

# 1. Build IPK
echo "==> Building IPK for $ARCH..."
mkdir -p "$STAGING_DIR/CONTROL"

cat > "$STAGING_DIR/CONTROL/control" <<EOF
Package: sing-box-tiny
Version: ${PKG_VERSION}-${PKG_RELEASE}
Depends: libc, ca-bundle, kmod-inet-diag, kmod-tun, kmod-netlink-diag
Provides: sing-box
Conflicts: sing-box
Section: net
Architecture: $ARCH
Maintainer: OpenWrt Community
Description: The universal proxy platform (tiny version)
EOF

cat > "$STAGING_DIR/CONTROL/conffiles" <<EOF
/etc/config/sing-box
/etc/sing-box/
EOF

cat > "$STAGING_DIR/CONTROL/postinst" <<'EOF'
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || /etc/init.d/sing-box enable
exit 0
EOF
chmod 755 "$STAGING_DIR/CONTROL/postinst"

cat > "$STAGING_DIR/CONTROL/prerm" <<'EOF'
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || /etc/init.d/sing-box stop
exit 0
EOF
chmod 755 "$STAGING_DIR/CONTROL/prerm"

# Run ipkg-build
"$SCRIPT_DIR/ipkg-build" -m "" "$STAGING_DIR" "$OUTPUT_DIR"

IPK_FILE="$OUTPUT_DIR/sing-box-tiny_${PKG_VERSION}-${PKG_RELEASE}_${ARCH}.ipk"
if [ ! -f "$IPK_FILE" ]; then
    echo "Error: Expected IPK file $IPK_FILE was not created!"
    exit 1
fi
echo "==> Successfully created IPK: $(basename "$IPK_FILE")"

# 2. Build APK using ipk2apk
echo "==> Converting IPK to APK for $ARCH..."
"$SCRIPT_DIR/ipk2apk" "$IPK_FILE" "$OUTPUT_DIR"

DEFAULT_APK="$OUTPUT_DIR/sing-box-tiny-${PKG_VERSION}-r${PKG_RELEASE}.apk"
FINAL_APK="$OUTPUT_DIR/sing-box-tiny_${PKG_VERSION}-r${PKG_RELEASE}_${ARCH}.apk"

if [ -f "$DEFAULT_APK" ]; then
    mv "$DEFAULT_APK" "$FINAL_APK"
fi

if [ ! -f "$FINAL_APK" ]; then
    echo "Error: Expected APK file $FINAL_APK was not created!"
    exit 1
fi
echo "==> Successfully created APK: $(basename "$FINAL_APK")"
