# AGENTS.md
This repo is the shared workspace for local and cloud agents. Heavy reference repos are hydrated into `reference-repos/` at container start/resume; they are not committed to git.

## Layout
- `reference-repos/` – up-to-date clones of external repos (gitignored)
- `manifests/references.yaml` – list of repos/branches/sparse paths to hydrate
- `scripts/sync-refs.sh` – clones/updates refs (shallow, sparse-aware)
- `scripts/container-setup.sh` – container Setup hook (versioned here)
- `scripts/container-maintenance.sh` – container Maintenance hook (versioned here)
- `docs/codex-environment.md` – detailed environment notes

## Codex Cloud environment (summary)
- Image: `openai/codex-universal` (Ubuntu 24.04; Python/Node/Rust/Go/Ruby/etc. preinstalled)
- Internet: enabled
- Env vars: expects `OPENAI_API_KEY` at runtime (do **not** commit secrets)
- GitHub CLI: preinstalled and authenticated via `GH_TOKEN` for read-only GitHub access
- Container caching: on
- Setup script: `bash scripts/container-setup.sh`
- Maintenance script: `bash scripts/container-maintenance.sh`

## Local refresh
- Manually: `bash scripts/sync-refs.sh reference-repos manifests/references.yaml`

## Don’ts
- Don’t commit the contents of `reference-repos/`.
- Don’t store API keys in the repo. Use environment variables or your shell.

---
