#!/usr/bin/env python3
"""Fail a pull request when a changed feature does not bump its version.

For every ``src/<feature>/`` directory touched relative to the base branch, this
compares the ``version`` field of ``devcontainer-feature.json`` at ``HEAD``
against the base branch. A feature that changed but kept (or lowered) its version
fails the check, because ``devcontainers/action`` publishes by version and would
silently skip the unchanged tag. Brand-new features (absent on the base branch)
are exempt.

Versions are compared by their leading numeric components (``1.10.0`` sorts
above ``1.9.0``), so this does not fall into the string-comparison trap.
"""
import argparse
import json
import os
import re
import subprocess
import sys


def run_git(args):
    return subprocess.run(
        ["git", *args],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    ).stdout.decode("utf-8")


def changed_files(base_branch):
    try:
        out = run_git(["diff", "--name-only", f"origin/{base_branch}"])
    except subprocess.CalledProcessError as exc:
        print(f"Error: {exc.stderr.decode('utf-8')}", file=sys.stderr)
        sys.exit(1)
    return [line for line in out.splitlines() if line]


def feature_version(directory, ref):
    """Return the version string, or None if the file is absent at ``ref``."""
    target = "HEAD" if ref == "HEAD" else f"origin/{ref}"
    try:
        out = run_git(["show", f"{target}:{directory}/devcontainer-feature.json"])
    except subprocess.CalledProcessError as exc:
        message = exc.stderr.decode("utf-8")
        if "does not exist" in message or "exists on disk, but not in" in message:
            return None
        print(f"Error: {message}", file=sys.stderr)
        sys.exit(1)
    try:
        return json.loads(out).get("version")
    except json.JSONDecodeError as exc:
        print(f"Error decoding {directory}/devcontainer-feature.json@{ref}: {exc}",
              file=sys.stderr)
        sys.exit(1)


def as_tuple(version):
    parts = []
    for token in re.split(r"[.+\-]", version or ""):
        if token.isdigit():
            parts.append(int(token))
        else:
            break
    return tuple(parts)


def bump_missing(directory, base_branch):
    current = feature_version(directory, "HEAD")
    base = feature_version(directory, base_branch)

    if base is None:
        print(f"[skip] {directory}: new feature, no version bump required")
        return False
    if current is None:
        print(f"[fail] {directory}: version missing at HEAD")
        return True
    if as_tuple(current) > as_tuple(base):
        print(f"[ok]   {directory}: {base} -> {current}")
        return False
    print(f"[fail] {directory}: version not bumped (base {base}, head {current})")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--base-branch",
        default=os.environ.get("GITHUB_BASE_REF", "main"),
        help="base branch to compare against (default: GITHUB_BASE_REF or main)",
    )
    args = parser.parse_args()

    changed_dirs = sorted(
        {os.path.dirname(path) for path in changed_files(args.base_branch)
         if path.startswith("src/") and os.path.dirname(path).count("/") == 1}
    )
    if not changed_dirs:
        print("No changed features under src/; nothing to check.")
        return

    failed = any(bump_missing(directory, args.base_branch) for directory in changed_dirs)
    if failed:
        sys.exit(1)


if __name__ == "__main__":
    main()
