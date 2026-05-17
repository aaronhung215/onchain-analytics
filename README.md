# onchain-analytics

Hands-on onchain data analysis on [Dune](https://dune.com), worked
agent-assisted via the Dune MCP server + Claude Code. SQL-native blockchain
analytics: discover the data, write DuneSQL, iterate, publish public dashboards.

## Status

🚧 In progress. Building toward published dashboards + a write-up. This README
will link to live dashboards as they go public — until then, treat items below
as work in progress, not finished results.

## Planned analyses

| # | Analysis | Query | Dashboard |
|---|---|---|---|
| 1 | Ethereum DEX volume by project, daily trend | `queries/eth_dex_volume.sql` | _pending_ |
| 2 | Stablecoin holder concentration (top-N share of supply) | `queries/stablecoin_holders.sql` | _pending_ |

Published dashboard URLs + one-line insights are tracked in `dashboards.md`.

## Repo layout

```
CLAUDE.md       # how this repo is worked (Dune MCP, DuneSQL conventions, targets)
README.md       # this file
queries/        # DuneSQL source (the source of truth for each dashboard)
notes/          # analysis notes → grows into the write-up
dashboards.md   # index of published dashboards (URL + insight)
```

## Approach

Queries are developed and run through the Dune MCP server connected to Claude
Code: draft SQL → run via MCP → inspect → iterate → publish dashboard. The `.sql`
files are the canonical source; the dashboards on Dune render them.

## Note on the SQL

Query files start as scaffolds encoding the right tables and patterns
(`dex.trades`, decoded/abstraction tables, `block_time` filtering, varbinary
address literals). They are verified and corrected by running them on Dune
before any results or dashboards are treated as accurate.
