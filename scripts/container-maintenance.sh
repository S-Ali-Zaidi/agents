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

# Upgrade Codex CLI
if command -v npm >/dev/null 2>&1; then
  npm update -g @openai/codex >/dev/null 2>&1 || true
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
