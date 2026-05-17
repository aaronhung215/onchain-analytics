# CLAUDE.md — onchain-analytics

> Public repo. Portfolio + skill-building for onchain data analysis on Dune.
> Claude Code auto-loads this. **Nothing private goes in this repo** (no salary
> goals, no job-search state, no referrer names — that lives in a separate
> private repo). This file is only about the Dune work.

---

## 0. PRIVACY & SECRETS (read first)

- This repo is **public**. Assume anything committed is world-readable.
- The Dune API key is configured via Claude Code at **`--scope user`** (stored
  in `~/.claude`, NOT in this repo). Never put the key in `.mcp.json`,
  `CLAUDE.md`, query files, or anywhere committed.
- If a Dune MCP setup ever needs to be re-run:
  `claude mcp add --scope user --transport http dune https://api.dune.com/mcp/v1 --header "x-dune-api-key: <KEY>"`
  — run it in a terminal, never paste the key into a tracked file.

---

## 1. WHAT THIS REPO IS

Hands-on onchain data analysis using Dune. Goal: publish public Dune dashboards
+ a write-up, demonstrating practical blockchain-data analytics (SQL-native,
agent-assisted via the Dune MCP). The SQL here is the source; the published
dashboards live on dune.com under the Dune account; `dashboards.md` is the index.

## 2. DUNE MCP — how this repo is worked

The Dune MCP server is connected to Claude Code. Available capability: discover
datasets, write DuneSQL, execute queries, inspect results, manage
visualizations, build dashboards — conversationally. Workflow:

1. Draft / edit a query in `queries/*.sql`.
2. Ask Claude Code to run it via the Dune MCP, inspect results, iterate.
3. When a query is solid, build/refresh its dashboard via the MCP (or the Dune
   web UI), then record the public URL + one-line insight in `dashboards.md`.

Uses the connected Dune account's API credits. Free tier ≈ 2,500 credits/month —
sufficient for this repo's scope. Check with the MCP's usage tool if unsure.

## 3. DuneSQL CONVENTIONS (Trino fork — not Postgres, not Spark)

- **Always filter by `block_time` (and `block_number` when possible) first** —
  cheapest way to limit the scan. Never run an unbounded full-table query.
- **Prefer decoded/abstraction tables over raw.** Use `dex.trades`,
  `tokens.transfers`, `prices.usd`, stablecoin abstractions — not hand-parsed
  `ethereum.logs`, unless nothing decoded exists.
- Addresses/hashes are **varbinary**; literal form is `0x...` with no quotes,
  no lowercasing: `WHERE token_address = 0xa0b8...`.
- Large numbers: `uint256` / `int256`; cast explicitly when comparing
  (DuneSQL/Trino is stricter about types than Spark was).
- Token amounts: divide raw by `10^decimals`; for USD use `prices.usd` or the
  amount fields already in `dex.trades`.
- Keep queries readable: CTEs over nested subqueries; one logical step per CTE.

## 4. CURRENT TARGETS (Level 2 — see plan in private tracker)

Two dashboards to publish, plus a write-up:

1. **ETH DEX volume** — daily DEX volume on Ethereum, split by project
   (Uniswap / PancakeSwap / Curve / …), trend over time.
   → starter: `queries/eth_dex_volume.sql`
2. **Stablecoin holder concentration** — holder distribution / concentration
   for a major stablecoin (e.g. USDC), top-N share of supply over time.
   → starter: `queries/stablecoin_holders.sql`
3. Short Medium write-up tying the two together (notes → `notes/`).

The `.sql` files are **v0 scaffolds, not verified**. They encode the right
table/pattern but must be run and corrected via the Dune MCP before being
treated as accurate. Do not present unrun SQL or its numbers as facts.

## 5. HONESTY DISCIPLINE (carries over from the job-search context)

The blockchain experience claim stays at **"studying / building toward
publishing dashboards"** until the dashboards are actually public. Only after
they are live + the write-up exists does it become "published N dashboards +
article". Never describe planned work as done. This applies to the README,
`dashboards.md`, and any external mention.

## 6. WORKING NOTES

- One concern per file. Git history is the version log — don't make
  `query_v2.sql`; edit in place and commit with a clear message.
- README and `dashboards.md` are public-facing — keep them accurate and free of
  unpublished claims.
