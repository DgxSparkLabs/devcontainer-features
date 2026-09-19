#!/usr/bin/env bash
# Expected-failure harness for Dev Container Features.
#
# Reads a JSON array of cases and, for each, builds a throwaway devcontainer that
# references the local feature and asserts the build FAILS (non-zero exit) and,
# when `expect_log` is given, that the build output contains that substring.
#
# This covers negative paths the official `devcontainer features test` cannot:
# its scenarios only assert a *successful* build plus post-start checks, so a
# feature that must reject an unsupported base image has no home there.
#
# Case shape (all keys except expect_log are required):
#   { "name": "...", "feature": "vault", "image": "...", "options": {}, "expect_log": "..." }
#
# Usage: expected-failure.sh <cases.json>
set -uo pipefail

CASES_FILE="${1:?usage: expected-failure.sh <cases.json>}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKSPACE_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORKSPACE_ROOT"' EXIT

pass=0
fail=0
count="$(jq 'length' "$CASES_FILE")"

for i in $(seq 0 $((count - 1))); do
    case_json="$(jq -c ".[$i]" "$CASES_FILE")"
    name="$(jq -r '.name' <<<"$case_json")"
    feature="$(jq -r '.feature' <<<"$case_json")"
    image="$(jq -r '.image' <<<"$case_json")"
    options="$(jq -c '.options // {}' <<<"$case_json")"
    expect_log="$(jq -r '.expect_log // empty' <<<"$case_json")"

    echo "======================================================================"
    echo "Case: $name  (feature=$feature image=$image)"
    echo "======================================================================"

    ws="$WORKSPACE_ROOT/$name"
    mkdir -p "$ws/.devcontainer"
    cp -r "$REPO_ROOT/src/$feature" "$ws/.devcontainer/$feature"
    jq -n --arg img "$image" --arg feat "./$feature" --argjson opts "$options" \
        '{image: $img, features: {($feat): $opts}}' > "$ws/.devcontainer/devcontainer.json"

    img_name="expected-fail-${name}-$$"
    out="$(devcontainer build --no-cache --image-name "$img_name" --workspace-folder "$ws" 2>&1)"
    code=$?
    docker rmi -f "$img_name" >/dev/null 2>&1 || true

    ok=true
    if [ "$code" -eq 0 ]; then
        echo "FAIL: build succeeded but was expected to fail"
        ok=false
    else
        echo "OK: build failed as expected (exit $code)"
    fi

    if [ -n "$expect_log" ]; then
        if grep -Fq "$expect_log" <<<"$out"; then
            echo "OK: found expected log substring: $expect_log"
        else
            echo "FAIL: expected log substring not found: $expect_log"
            echo "----- build output -----"
            echo "$out"
            echo "------------------------"
            ok=false
        fi
    fi

    if $ok; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
done

echo "======================================================================"
echo "Expected-failure summary: $pass passed, $fail failed (of $count)"
[ "$fail" -eq 0 ]
