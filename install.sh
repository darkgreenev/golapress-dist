#!/usr/bin/env bash
set -euo pipefail

repo="darkgreenev/golapress-dist"
version="${1:-latest}"
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
machine="$(uname -m)"

if [[ "$os" != "linux" ]]; then
  echo "install.sh currently supports Linux only. Use install.ps1 on Windows." >&2
  exit 1
fi

case "$machine" in
  x86_64|amd64) arch="amd64" ;;
  aarch64|arm64) arch="arm64" ;;
  *) echo "Unsupported architecture: $machine" >&2; exit 1 ;;
esac

asset="golapress-linux-${arch}.tar.gz"
if [[ "$version" == "latest" ]]; then
  url="https://github.com/${repo}/releases/latest/download/${asset}"
else
  url="https://github.com/${repo}/releases/download/${version}/${asset}"
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Downloading ${asset} from ${url}"
curl -fL "$url" -o "$tmp_dir/$asset"

mkdir -p "$root_dir/bin" "$root_dir/data/media" "$root_dir/themes" "$root_dir/plugins"
tar -xzf "$tmp_dir/$asset" -C "$tmp_dir"
cp "$tmp_dir/golapress-linux-${arch}/golapress" "$root_dir/bin/golapress"
chmod +x "$root_dir/bin/golapress"

if [[ ! -f "$root_dir/.env" ]]; then
  cp "$root_dir/.env.example" "$root_dir/.env"
  echo "Created .env from .env.example. Change ADMIN_PASSWORD before exposing the app."
fi

echo "Installed goLaPress to $root_dir/bin/golapress"
echo "Run: ./examples/run-linux.sh"
