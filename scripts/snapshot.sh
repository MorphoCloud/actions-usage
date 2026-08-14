#!/usr/bin/env bash
# Snapshot one month of org Actions billing usage into data/YYYY-MM.json.
#
#   scripts/snapshot.sh            # previous month
#   scripts/snapshot.sh 2026-05    # specific month (backfill)
#
# Runs locally: the billing endpoint rejects fine-grained PATs and GITHUB_TOKEN,
# so this relies on the local gh login having admin:org scope.
set -euo pipefail
cd "$(dirname "$0")/.."

ORG=MorphoCloud

if [ $# -ge 1 ]; then
  ym=$1
else
  # Last day of the previous month, portably (BSD/macOS date, then GNU).
  ym=$(date -v1d -v-1d +%Y-%m 2>/dev/null || date -d "$(date +%Y-%m-01) -1 day" +%Y-%m)
fi
y=${ym%-*}
m=$((10#${ym#*-}))
out="data/$ym.json"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
gh api "organizations/$ORG/settings/billing/usage?year=$y&month=$m" > "$tmp"
jq -e '.usageItems' "$tmp" > /dev/null

# Empty is a failure, not a snapshot: this org has daily cron activity, so an
# empty month means the fetch is wrong (auth, retention) rather than zero usage.
if [ "$(jq '.usageItems | length' "$tmp")" -eq 0 ]; then
  echo "ERROR: $ym returned no usage items; refusing to save." >&2
  exit 1
fi

jq . "$tmp" > "$out"

git add "$out"
if git diff --cached --quiet; then
  echo "RESULT=unchanged MONTH=$ym"
else
  git commit -q -m "snapshot: $ym"
  git push -q
  echo "RESULT=committed MONTH=$ym MINUTES=$(jq '[.usageItems[] | select(.sku=="Actions Linux") | .quantity] | add' "$out")"
fi
