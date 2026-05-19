# onchain-analytics

Hands-on onchain data analysis on [Dune](https://dune.com), worked
agent-assisted via the Dune MCP server + Claude Code. SQL-native blockchain
analytics: discover the data, write DuneSQL, iterate, publish public dashboards.

## Status

📊 **2 of 2 dashboards live.** Both the Ethereum DEX market share dashboard and
the USDC holder concentration dashboard are published on Dune. The short write-up
tying both together is still in progress — until that's done, treat the synthesis
as work-in-progress (the individual dashboards stand on their own).

## Planned analyses

| # | Analysis | Query | Dashboard |
|---|---|---|---|
| 1 | Ethereum DEX market share (weekly share, 90d snapshot, daily volume) | `queries/eth_dex_volume.sql`, `queries/eth_dex_weekly_share.sql` | [ETH DEX Market Share — 90d](https://dune.com/aaronpk/ethereum-dex-market-share-90d) |
| 2 | USDC holder concentration on Ethereum (bucket shares + top-10 holders) | `queries/stablecoin_holders.sql`, `queries/stablecoin_top_holders.sql` | [USDC Holder Concentration — Ethereum](https://dune.com/aaronpk/usdc-holder-concentration-ethereum) |

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
