#!/usr/bin/env bash
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$root"
case "${1:-all}" in
    all) arches=(linux-x64 linux-aarch64) ;;
    linux-x64|linux-aarch64) arches=("$1") ;;
    *) echo 'Usage: bash build-assistant.sh [all|linux-x64|linux-aarch64]' >&2; exit 1 ;;
esac
export OPENCODE_VERSION=${OPENCODE_VERSION:-$(bun -e 'console.log(require("./package.json").version)')+assistant.$(git rev-parse --short=12 HEAD)}
export OPENCODE_CHANNEL=assistant
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
# Fetch native optional dependencies for both Linux architectures without changing the lockfile.
bun install --frozen-lockfile --os=linux --cpu='*'
for arch in "${arches[@]}"; do
    case "$arch" in
        linux-x64) target=opencode-linux-x64-baseline; package=cli-linux-x64-baseline ;;
        linux-aarch64) target=opencode-linux-arm64; package=cli-linux-arm64 ;;
    esac
    output="$root/artifacts/$arch"
    # Build each target into its own directory; build.ts clears --outdir on entry.
    bun run packages/cli/script/build.ts --skip-install --target="$target" --outdir="$root/artifacts/.build/$arch"
    mkdir -p "$output"
    install -m 755 "$root/artifacts/.build/$arch/$package/bin/opencode" "$output/opencode-v2"
    (
        cd "$output"
        sha256sum opencode-v2 > SHA256SUMS
        printf 'version=%s\nsource=%s\nupstream_pr=%s\ntarget=%s\n' \
            "$OPENCODE_VERSION" "$(git rev-parse HEAD)" \
            'https://github.com/anomalyco/opencode/pull/56044' "$target" > build-info.txt
    )
done
printf 'Builds saved under %s/artifacts/\n' "$root"
