#!/usr/bin/env python3
"""Round-robin a JSON list of feature names into <= MAX_BINS comma-joined bins.

The feature list is read from ``argv[1]`` (a JSON array) or, if absent, from
stdin. ``MAX_BINS`` comes from ``--max-bins`` or the ``MAX_BINS`` environment
variable (default 256, GitHub's matrix-combination cap). Output is a compact
JSON array of comma-joined feature groups suitable for a workflow matrix, e.g.
``["bitwarden-cli,vault","mise"]``.

Round-robin (rather than contiguous chunks) keeps bin sizes within one of each
other, so slow features spread evenly across jobs instead of piling into the
last bin.
"""
import argparse
import json
import os
import sys


def shard(features, max_bins):
    features = sorted(f for f in features if f)
    bin_count = min(len(features), max(1, max_bins))
    if bin_count == 0:
        return []
    bins = [[] for _ in range(bin_count)]
    for index, feature in enumerate(features):
        bins[index % bin_count].append(feature)
    return [",".join(group) for group in bins]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("features", nargs="?", help="JSON array of feature names")
    parser.add_argument(
        "--max-bins",
        type=int,
        default=int(os.environ.get("MAX_BINS", "256")),
        help="maximum number of bins (default 256)",
    )
    args = parser.parse_args()

    raw = args.features if args.features is not None else sys.stdin.read()
    features = json.loads(raw or "[]")
    print(json.dumps(shard(features, args.max_bins), separators=(",", ":")))


if __name__ == "__main__":
    main()
