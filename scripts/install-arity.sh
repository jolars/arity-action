#!/usr/bin/env sh
set -eu

REPO="${ARITY_REPO:-jolars/arity}"
INSTALL_DIR="${ARITY_INSTALL_DIR:-$HOME/.local/bin}"
VERSION="${ARITY_VERSION:-latest}"
VERIFY="${ARITY_VERIFY_CHECKSUM:-true}"

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
Linux)
	case "$arch" in
	x86_64 | amd64) target="x86_64-unknown-linux-gnu" ;;
	aarch64 | arm64) target="aarch64-unknown-linux-gnu" ;;
	*)
		echo "Unsupported Linux architecture: $arch" >&2
		exit 1
		;;
	esac
	;;
Darwin)
	case "$arch" in
	x86_64 | amd64) target="x86_64-apple-darwin" ;;
	arm64 | aarch64) target="aarch64-apple-darwin" ;;
	*)
		echo "Unsupported macOS architecture: $arch" >&2
		exit 1
		;;
	esac
	;;
*)
	echo "Unsupported operating system: $os" >&2
	exit 1
	;;
esac

asset="arity-${target}.tar.gz"

if [ "$VERSION" = "latest" ]; then
	base="https://github.com/${REPO}/releases/latest/download"
else
	case "$VERSION" in
	v*) tag="$VERSION" ;;
	*) tag="v${VERSION}" ;;
	esac
	base="https://github.com/${REPO}/releases/download/${tag}"
fi
url="${base}/${asset}"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT INT TERM

echo "Downloading ${asset} (${VERSION})..."
curl --proto '=https' --tlsv1.2 -fLsS "$url" -o "$tmpdir/$asset"

if [ "$VERIFY" = "true" ]; then
	# Fetch the published checksum sidecar. Older releases may not have one, in
	# which case we warn and continue rather than fail.
	if curl --proto '=https' --tlsv1.2 -fLsS "${url}.sha256" -o "$tmpdir/$asset.sha256"; then
		expected="$(awk '{print $1}' "$tmpdir/$asset.sha256")"
		if command -v sha256sum >/dev/null 2>&1; then
			actual="$(sha256sum "$tmpdir/$asset" | awk '{print $1}')"
		elif command -v shasum >/dev/null 2>&1; then
			actual="$(shasum -a 256 "$tmpdir/$asset" | awk '{print $1}')"
		else
			echo "No sha256sum or shasum available; cannot verify checksum" >&2
			exit 1
		fi
		if [ "$expected" != "$actual" ]; then
			echo "Checksum mismatch for ${asset}" >&2
			echo "  expected: $expected" >&2
			echo "  actual:   $actual" >&2
			exit 1
		fi
		echo "Checksum verified."
	else
		echo "Warning: no published checksum for ${asset}; skipping verification." >&2
	fi
fi

tar -xzf "$tmpdir/$asset" -C "$tmpdir"
mkdir -p "$INSTALL_DIR"
install -m 755 "$tmpdir/arity" "$INSTALL_DIR/arity"

echo "Installed arity to $INSTALL_DIR/arity"
