#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_home=${DSH_HOME:-"$repo_root/.dsh-test-home"}
export DSH_HOME="$test_home"
export DSH_WORKSPACE_ROOT="$repo_root/fairy-voice"
export DSH_FAIRY_REPO_ROOT="$repo_root"
export DSH_FAIRY_TEST_HOME="$test_home"
export DSH_FAIRY_PROFILE_ROOT="$repo_root/profiles/web"
export DSH_ACCEPTED_BASELINE_ROOT="$test_home/accepted-baselines"

mkdir -p "$DSH_HOME"
mkdir -p "$DSH_HOME/.agent-presets/fairy" "$DSH_HOME/accepted-baselines"
for asset in runtime personality style canon behavior; do
  if [ -e "$DSH_HOME/.agent-presets/fairy/$asset" ]; then
    mv "$DSH_HOME/.agent-presets/fairy/$asset" "$DSH_HOME/.agent-presets/fairy/$asset.previous.$$"
  fi
  cp -R "$repo_root/.agent-presets/fairy/$asset" "$DSH_HOME/.agent-presets/fairy/$asset"
done

# Keep the profile in the candidate repository while presenting it at the
# location expected by the DSH CLI. The node helper mounts it with an absolute
# target and re-aims the profile's link: dependencies the same way: on Windows
# a relative junction target re-bases when reached through the mount, so the
# POSIX `ln -s` form silently breaks plugin resolution there.
mkdir -p "$DSH_HOME/profiles"
if [ -e "$DSH_HOME/profiles/web" ] && [ ! -L "$DSH_HOME/profiles/web" ]; then
  mv "$DSH_HOME/profiles/web" "$DSH_HOME/profiles/web.previous.$$"
fi
node "$repo_root/scripts/link-profile.mjs"

echo "[1/3] package tests"
if command -v pnpm >/dev/null 2>&1; then
  # One root workspace install provides the dependency closure every linked
  # plugin resolves from its real directory; profile-local node_modules cannot.
  (cd "$repo_root" && pnpm install --frozen-lockfile --ignore-scripts)
else
  echo "pnpm is required for the workspace install" >&2
  exit 1
fi
(cd "$repo_root/fairy-visual/dsh-fairy-visual" && npm test)
(cd "$repo_root/fairy-voice/dsh-fairy-voice" && npm test)

echo "[2/3] profile dependency check"
if command -v pnpm >/dev/null 2>&1; then
  (cd "$repo_root/profiles/web" && pnpm install --frozen-lockfile --ignore-scripts)
  # An install rewrites the link: entries with relative targets again; restore
  # the absolute form before the smoke test boots through the mount.
  node "$repo_root/scripts/link-profile.mjs"
else
  echo "pnpm is required for profile installation" >&2
  exit 1
fi

echo "[3/3] isolated profile smoke test"
if command -v dsh >/dev/null 2>&1; then
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout 8 dsh --profile web --no-open --port 0 || test $? -eq 124
  else
    smoke_log="$DSH_HOME/dsh-smoke.log"
    dsh --profile web --no-open --port 0 >"$smoke_log" 2>&1 &
    smoke_pid=$!
    trap 'kill "$smoke_pid" 2>/dev/null || true' EXIT INT TERM
    sleep 6
    if ! kill -0 "$smoke_pid" 2>/dev/null; then
      echo "DSH exited during isolated smoke test" >&2
      sed -n '1,160p' "$smoke_log" >&2
      exit 1
    fi
    grep -Eq '^dsh web: http://127\.0\.0\.1:[0-9]+' "$smoke_log"
    kill "$smoke_pid" 2>/dev/null || true
    wait "$smoke_pid" 2>/dev/null || true
    trap - EXIT INT TERM
  fi
else
  echo "dsh CLI is required for the live smoke test" >&2
  exit 1
fi
