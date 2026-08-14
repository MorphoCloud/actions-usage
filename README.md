# actions-usage

Monthly snapshots of GitHub Actions billing usage for the MorphoCloud org,
saved because GitHub's own retention is limited (summarized reports: 1 year;
workflow-level detail: 31 days; API window undocumented).

## Data

`data/YYYY-MM.json` is the raw response of the
[billing usage report API](https://docs.github.com/en/rest/billing/usage)
for that month: per-repo, per-day, per-SKU line items. Series starts 2026-06.

Minutes per repo for a month:

```sh
jq -r '[.usageItems[] | select(.sku=="Actions Linux")] | group_by(.repositoryName)[]
       | "\(.[0].repositoryName)\t\(map(.quantity) | add)"' data/2026-07.json
```

Net billed dollars for a month:

```sh
jq '[.usageItems[].netAmount] | add' data/2026-07.json
```

## How it updates

Manually, once a month after the month closes: `scripts/snapshot.sh`
(run locally by an org admin) fetches the previous month and commits it.
There is no Actions workflow on purpose — the billing endpoint rejects
fine-grained PATs and `GITHUB_TOKEN`, and we are not willing to park an
`admin:org` classic token in repo secrets. A scheduled reminder covers
the "remember to run it" half.

`scripts/snapshot.sh 2026-05` backfills a specific month, while it is
still inside GitHub's API window.

Caveats for later analysis:

- Public repos appear with fully discounted (free) minutes; only private
  repo minutes count against the plan's included quota.
- Repos transferred into the org (June 2026) have no pre-transfer usage
  here; that billed to the previous owner.
