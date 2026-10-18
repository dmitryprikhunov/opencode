# OpenCode Assistant builds

This personal fork integrates [anomalyco/opencode#56044](https://github.com/anomalyco/opencode/pull/56044),
commit `5b790a24a396d6799b3f0b719057604ce52f5c4d`, on upstream `dev`
at `214fb7fdbab9ad13773629839f1178382400cf97` (V2 2.0.32).
It is not affiliated with the OpenCode team.

Use Bun 1.4.2 (the root packageManager version), Node 24.22.0, Git, Python 3,
make, g++, pkg-config, curl and unzip on glibc Linux x86_64 or aarch64.
The development image supplies these tools on either architecture:

```bash
docker build -f Dockerfile.assistant-dev -t opencode-assistant-dev:1.4.2 .
docker run --rm -it -v "$PWD:/src" opencode-assistant-dev:1.4.2
```

Docker selects the host architecture. Use a native aarch64 host for an aarch64
development container, or configure Docker's QEMU emulation separately.
Inside the container, or with the native tools on PATH:

```bash
export ELECTRON_SKIP_BINARY_DOWNLOAD=1
bun install --frozen-lockfile --os=linux --cpu='*'
bun dev serve --port 4096
# In another shell:
bun run dev:web
```

Run the app development server on port 4444 if a fixed port is needed:
`cd packages/app && bun dev -- --port 4444`.

Build both Linux targets, including the rebuilt, embedded web UI:

```bash
bash build-assistant.sh
# Or build one target:
bash build-assistant.sh linux-x64
bash build-assistant.sh linux-aarch64
```

Outputs are `artifacts/linux-x64/opencode-v2` (x64 baseline for CPU compatibility)
and `artifacts/linux-aarch64/opencode-v2` (arm64). Both are glibc binaries for
the Debian-based assistant image. Bun cross-compiles either target from either
host. The upstream build verifies that the executable and all embedded native
libraries match the target architecture. Execution smoke tests require the
matching host or emulation. Each output has `SHA256SUMS` and `build-info.txt`.
The version defaults to `2.0.32+assistant.<source-commit>`; override it by setting
`OPENCODE_VERSION` to another V2 version before building.

Checks:

```bash
cd packages/app
bun run test
bun typecheck
cd ../..
bun run check
```

To build the separate `opencode-assistant` image with one of these binaries:

```bash
docker build -t opencode-assistant:custom \
  --build-arg OPENCODE_USE_LOCAL_BINARY=true \
  --build-context opencode_binary=/absolute/path/to/artifacts/linux-x64 \
  /absolute/path/to/opencode-assistant
```

Use `--platform linux/arm64` and the aarch64 binary for an ARM image. Its final
runtime checks need a native ARM builder or QEMU. Supply each architecture's
binary in a separate image build.
