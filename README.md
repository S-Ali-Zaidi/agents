# Agent Workspace

This repository provides a shared workspace for local and cloud agents.  The
workspace is lightweight; large upstream projects are hydrated into the
`reference-repos/` directory on container start or resume and are **not**
committed to git.

## Layout

- `reference-repos/` – up-to-date clones of external reference repositories
  (gitignored)
- `manifests/references.yaml` – list of repositories and sparse paths to hydrate
- `scripts/` – setup and maintenance helpers
  - `container-setup.sh`
  - `container-maintenance.sh`
  - `sync-refs.sh`
- `docs/` – additional environment notes

## Refreshing reference repositories

Reference repositories can be refreshed manually:

```bash
bash scripts/sync-refs.sh reference-repos manifests/references.yaml
```

## Environment

The workspace runs in the `openai/codex-universal` image (Ubuntu 24.04) with
internet access enabled.  Secrets such as `OPENAI_API_KEY` should be supplied via
environment variables and must never be committed.

## Don’ts

- Do not commit the contents of `reference-repos/`.
- Do not store API keys or other secrets in the repository.

