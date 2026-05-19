# New-token cold-start: early DEX signal vs 14-day survival

> Quick research note (2026-05-19). For an exchange's listing committee or for
> any recommendation system that needs to score newly-deployed tokens before
> they have own-platform history, the question is: **does an onchain DEX
> signal in the first few days predict whether the token is still alive a
> couple of weeks later?** Answer here, with caveats.

## TL;DR

- **15x survival-rate gap between top and bottom early-volume buckets**, monotonic across buckets. First-3-day DEX volume is a strong, usable cold-start ranking signal.
- But also: **91% of new tokens come into the world below $10k early volume**, and ≥87% of those die within ~3 weeks. The recommendation universe is mostly noise; the value of even a crude filter is huge.
- Limitations are real and listed below — most importantly the "still alive" definition here is extremely weak ("≥ 1 trade in days 14-20"). Stronger definitions would shift the curves but not the monotonicity.

## Methodology

- **Source**: `dex.trades` (Dune spell), Ethereum only.
- **Scan window**: last 60 days of `dex.trades`, partition-pruned via `block_month` + `block_time`.
- **Cohort**: tokens whose **first observed DEX trade** fell in the window `[today-30 days, today-21 days]`. This guarantees each token has at least 14 days of post-launch data observed before "today", but is still young enough to count as "new". 16,944 tokens.
- **Early signal**: USD volume in days `d0` to `d2` (the token's first three calendar days, by `block_date`).
- **Outcome**: did the token have **any** trade in days `d14` to `d20` (a 7-day window starting two weeks after first trade)? "Survived" = yes.
- **Cost**: 0.179 credits (Dune query `7530...988` — kept temp; see Reproducibility).

Important shortcuts in this scan:
- "First trade" is the first trade we **observe in the 60-day scan window**. A token that traded earlier and then went quiet would be misclassified as new. Realistically rare for active tokens.
- "Token" = `token_bought_address`. Same address could in principle be re-issued on a different chain, but on Ethereum this is essentially 1:1 with contract identity.
- Tokens with no priced trade (`amount_usd IS NULL`) are excluded — affects very illiquid pairs whose price Dune couldn't compute.

## Results

| Early signal (d0–d2 USD volume) | # tokens | # still active in d14–d20 | Survival rate | Avg d14–d20 volume | Avg d14–d20 unique traders |
|---|---:|---:|---:|---:|---:|
| ≥ $1M | 31 | 28 | **90.3%** | $239,049 | 149 |
| $100k – $1M | 289 | 149 | 51.6% | $8,849 | 21 |
| $10k – $100k | 1,204 | 285 | 23.7% | $1,539 | 4 |
| $1k – $10k | 4,522 | 555 | 12.3% | $322 | 1 |
| < $1k | 10,898 | 680 | **6.2%** | $85 | 0.4 |
| **Total** | **16,944** | 1,697 | 10.0% | — | — |

## Interpretation

### (a) Monotone signal, very strong gradient
Survival rate falls cleanly across buckets: 90 → 52 → 24 → 12 → 6%. No non-monotonic surprises (no inverted-U, no flat zones). This means the raw signal can act directly as a monotone ranker — no segmentation or piecewise treatment needed before more sophisticated features come in.

### (b) The universe is mostly dead-on-arrival
The two bottom buckets (early volume < $10k) hold **91% of all new tokens** (15,420 / 16,944). Together they account for ~73% of the 1,697 survivors, but those "survivors" are extremely thin — averaging $85–$322 in days 14–20 and well under 2 unique traders. Most are technically alive but commercially irrelevant.

For any recommendation surface, **the first job is filtering out this 91%**, not ranking inside it. A simple `early_volume ≥ $10k` cut removes the bulk of noise.

### (c) The interesting zone is the middle bucket
The top bucket (90% survival) is "obviously recommendable". The bottom buckets are "obviously not". The middle bucket — $10k to $100k early volume, with 24% survival — is the **decision-meaningful** zone, where a model adds real value over a hard threshold rule.

## Implications for a cold-start ranker

Features available **before a token has own-platform history** (so usable at listing-decision or recommendation-eligibility time):

| Feature category | Examples | Expected strength |
|---|---|---|
| Volume momentum | d0–2 USD volume, d0–2 trade count | High (validated above) |
| Trader diversity | d0–2 distinct takers, # distinct DEX venues | Medium-high (wash-trading filter) |
| Holder dispersion | d0–2 distinct buyer count, top-10 holder concentration | High (anti-manipulation signal) |
| Deploy context | Factory contract used, deployer's prior tokens | Medium |
| Token metadata | Verified contract, presence of mint/owner functions, audit status | High (risk signal) |
| Liquidity depth | TVL across pools, # pools | Medium |
| Off-chain | Social mentions, listing on CMC/CoinGecko | Medium (hard to obtain at scale) |

**Outcome / label** options, from loose to strict:
- L1 — any trade in days 14-20 (used here; too generous, gives 10% baseline)
- L2 — ≥ $10k cumulative volume in days 14-20
- L3 — ≥ 10 distinct takers in days 14-20
- L4 — still in top-N new tokens by 30-day volume

In practice a useful production label is some combination — e.g. multi-task with L2 and L3 as separate heads, or a regression on log(d14–d20 volume).

## Limitations (must-state in any external use)

1. **"Survived" is extremely weak.** A single $5 trade counts. Replicating with L2 (≥ $10k) or L3 (≥ 10 distinct takers) would shift the table downward across all buckets and shrink the top-bucket survival number.
2. **No control for deploy size / capital backing.** A VC-backed token with a coordinated launch hits $1M day 0 by design; a grassroots meme that organically hits $1M is a different animal. Both end up in the same top bucket here.
3. **No wash-trading filter.** Bottom buckets in particular can be inflated by deployer self-trades. Distinct-taker counts would help, but this specific query doesn't apply that filter.
4. **Ethereum only.** Base / Arbitrum / Solana new-token ecosystems behave very differently (Solana's meme-coin birth/death cycle is much faster, for instance). Findings here generalise poorly.
5. **30-day window is short for true survival.** Real survival analysis needs 6+ months and proper censoring; this is a quick snapshot.
6. **Cohort is a single macro window.** Whether we sampled during a bull or bear period meaningfully shifts base rates. A robust version would run rolling cohorts and report the variation.
7. **`amount_usd IS NULL` exclusion bias.** Tokens Dune can't price (very illiquid pairs, exotic stables) drop out — likely under-represents the long tail.

## Follow-up research worth doing

| Follow-up | Why | Approx cost |
|---|---|---|
| Re-run with L3 label (≥ 10 distinct takers in d14-20) | More meaningful "alive" definition | ~0.2 credits |
| Add d0–2 **distinct takers** as second signal axis | Cross-tab vs volume — should make wash-trade effects visible | ~0.3 credits |
| Repeat on Base / Arbitrum / Solana | Quantify how chain-specific the calibration is | ~0.3 credits each |
| Rolling cohorts over 6 months | Measure base-rate variation across macro phases | ~3-5 credits |
| Join to `tokens.erc20` metadata + contract-verification flags | Add contract-quality features alongside volume | ~0.2 credits |

## Reproducibility

- SQL is in the Dune query (not committed to `queries/` yet — held as a `_temp` query while iterating). If this research line continues, the SQL should move to `queries/new_token_cold_start.sql` on its own PR.
- Single execution at 0.179 credits.
- All numbers above are direct outputs of the query, not estimates.
