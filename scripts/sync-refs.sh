#!/usr/bin/env bash
set -euo pipefail

# Usage: bash scripts/sync-refs.sh [DEST_DIR] [MANIFEST]
DEST="${1:-reference-repos}"
MANIFEST="${2:-manifests/references.yaml}"

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing $1"; exit 1; }; }
need git
need yq

mkdir -p "$DEST"
count=$(yq '.repos | length' "$MANIFEST")

for ((i=0; i<count; i++)); do
  name=$(yq -r ".repos[$i].name" "$MANIFEST")
  url=$(yq -r ".repos[$i].url" "$MANIFEST")
  branch=$(yq -r ".repos[$i].branch" "$MANIFEST")
  mapfile -t sparse < <(yq -r ".repos[$i].sparse[]" "$MANIFEST" 2>/dev/null || true)

  dest="$DEST/$name"

  if [ -d "$dest/.git" ]; then
    echo "[refs] updating $name..."
    git -C "$dest" fetch --prune --depth 1 origin "$branch"
    git -C "$dest" checkout -qf FETCH_HEAD
  else
    echo "[refs] cloning $name..."
    git clone --depth 1 --no-tags --single-branch -b "$branch" "$url" "$dest"
  fi

  if [ "${#sparse[@]}" -gt 0 ]; then
    # If any entry probably refers to a file (heuristic: contains a dot and doesn't end with /),
    # switch to non-cone mode. Cone mode only supports directories.
    use_nocone=0
    for p in "${sparse[@]}"; do
      if [[ "$p" != */ && "$p" == *.* ]]; then
        use_nocone=1
        break
      fi
    done

    if [[ $use_nocone -eq 1 ]]; then
      git -C "$dest" sparse-checkout init --no-cone
      git -C "$dest" sparse-checkout set "${sparse[@]}"
    else
      git -C "$dest" sparse-checkout init --cone
      git -C "$dest" sparse-checkout set "${sparse[@]}"
    fi
  fi
done

echo "[refs] done"
