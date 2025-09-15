#!/usr/bin/env bash
set -euo pipefail
echo "[setup] start"
if ! command -v git >/dev/null 2>&1; then apt-get update -y && apt-get install -y git; fi
if ! command -v curl >/dev/null 2>&1; then apt-get update -y && apt-get install -y curl; fi
if ! command -v gh >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y apt-transport-https ca-certificates gnupg
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null
  chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
  apt-get update -y
  apt-get install -y gh
fi
GH_TOKEN_ENV="${GH_TOKEN:-${GITHUB_TOKEN:-${GH_Token:-}}}"
if command -v gh >/dev/null 2>&1 && [ -n "$GH_TOKEN_ENV" ]; then
  tmpfile="$(mktemp)"
  trap 'rm -f "$tmpfile"' EXIT
  chmod 600 "$tmpfile"
  printf '%s' "$GH_TOKEN_ENV" >"$tmpfile"
  if gh auth login --with-token <"$tmpfile" >/dev/null 2>&1; then
    echo "[setup] GitHub CLI authenticated successfully."
  else
    echo "[setup] WARNING: GitHub CLI authentication failed. Continuing without authentication." >&2
  fi
  rm -f "$tmpfile"
  trap - EXIT
fi
if ! command -v yq >/dev/null 2>&1; then
  curl -sSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
fi
if [ -f "manifests/references.yaml" ] && [ -f "scripts/sync-refs.sh" ]; then
  bash scripts/sync-refs.sh "reference-repos" "manifests/references.yaml"
else
  echo "[setup] references manifest or sync script missing; skipping hydration"
fi

# Install Codex CLI and configure authentication
if command -v npm >/dev/null 2>&1; then
  npm install -g @openai/codex >/dev/null 2>&1 || true
fi

if [ -n "${OPENAI_API_KEY:-}" ]; then
  CODEX_HOME="$HOME/.codex"
  mkdir -p "$CODEX_HOME"
  cat >"$CODEX_HOME/auth.json" <<EOF
{"OPENAI_API_KEY":"$OPENAI_API_KEY"}
EOF
  cat >"$CODEX_HOME/config.toml" <<'EOF'
model = "gpt-5-mini"
model_reasoning_effort = "medium"
approval_policy = "never"
sandbox_mode = "workspace-write"
show_raw_agent_reasoning = true

[sandbox_workspace_write]
network_access = true
EOF
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
