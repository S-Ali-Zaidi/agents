# Codex Cloud Environment

## Image and toolchains
- Image: `openai/codex-universal`
- Toolchains (current config): Python 3.12, Node 20, Ruby 3.4.4, Rust 1.89.0, Go 1.24.3, Bun 1.2.14, PHP 8.4, Java 21, Swift 6.1

## Environment variables
- `OPENAI_API_KEY`: required for any OpenAI-compatible clients run inside the container.

## Setup script (runs on cold container after repo clone)
```bash
#!/usr/bin/env bash
set -euo pipefail
echo "[setup] start"
if ! command -v git >/dev/null 2>&1; then apt-get update -y && apt-get install -y git; fi
if ! command -v curl >/dev/null 2>&1; then apt-get update -y && apt-get install -y curl; fi
if ! command -v yq >/dev/null 2>&1; then
  curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
fi
if [ -f "manifests/references.yaml" ] && [ -f "scripts/sync-refs.sh" ]; then
  bash scripts/sync-refs.sh "reference-repos" "manifests/references.yaml"
else
  echo "[setup] references manifest or sync script missing; skipping hydration"
fi
# Optional dep warming (noop if no lockfiles present)
if [ -f package.json ]; then
  (command -v pnpm >/dev/null && pnpm install --frozen-lockfile || true) || \
  (command -v yarn >/dev/null && yarn install --frozen-lockfile || true) || \
  (command -v npm  >/dev/null && npm ci || npm install || true)
fi
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  (command -v uv >/dev/null && uv pip install -r requirements.txt || true) || \
  (command -v poetry >/dev/null && poetry install --no-interaction || true) || \
  (command -v pip >/dev/null && pip install -r requirements.txt || true)
fi
if [ -f Cargo.toml ]; then cargo fetch || true; fi
if [ -f go.mod ]; then go mod download || true; fi
echo "[setup] done"
```

## Maintenance script (runs on cached container resume)

```bash
#!/usr/bin/env bash
set -euo pipefail
echo "[maintenance] start"
if ! command -v yq >/dev/null 2>&1; then
  curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
fi
if [ -f "manifests/references.yaml" ] && [ -f "scripts/sync-refs.sh" ]; then
  bash scripts/sync-refs.sh "reference-repos" "manifests/references.yaml"
else
  echo "[maintenance] references manifest or sync script missing; skipping hydration"
fi
if [ -f package.json ]; then
  (command -v pnpm >/dev/null && pnpm install --frozen-lockfile || true) || \
  (command -v yarn >/dev/null && yarn install --frozen-lockfile || true) || \
  (command -v npm  >/dev/null && npm ci || true)
fi
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  (command -v uv >/dev/null && uv pip install -r requirements.txt || true) || \
  (command -v poetry >/dev/null && poetry install --no-interaction || true) || \
  (command -v pip >/dev/null && pip install -r requirements.txt || true)
fi
if [ -f Cargo.toml ]; then cargo fetch || true; fi
if [ -f go.mod ]; then go mod download || true; fi
echo "[maintenance] done"
```
