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

`monthly-snapshot.yml` runs on the second Sunday of each month and commits
the previous month. It fails loudly (email to the admin) rather than
skipping silently. Manual runs can backfill any month still inside GitHub's
API window via workflow dispatch.

Caveats for later analysis:

- Public repos appear with fully discounted (free) minutes; only private
  repo minutes count against the plan's included quota.
- Repos transferred into the org (June 2026) have no pre-transfer usage
  here; that billed to the previous owner.
