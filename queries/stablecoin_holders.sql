-- stablecoin_holders.sql
-- Holder concentration for USDC on Ethereum: top-10 / top-100 / top-1000 /
-- top-10000 / rest buckets, each as % of held supply.
--
-- Source: stablecoins_evm.balances — daily per-holder snapshot, USD-priced.
-- Schema verified via Dune MCP. (Replaces the v0 transfer-replay scaffold;
-- transfer replay was an approximation, this is a real daily snapshot.)
--
-- Cost notes:
--   * Snapshot is taken at MAX(day) so we always read one day's data.
--   * blockchain + token_address filters bound the scan to USDC Ethereum only.
--   * stablecoins_evm.balances has no partition columns, so the scan is
--     metadata-pruned rather than partition-pruned — expect ~4-5 credits/run.
--
-- "Supply" caveat:
--   `total_balance` here is the sum across all addresses with balance > 0 on
--   that day. That includes CEX cold storage, bridge escrows, and the Circle
--   treasury — which inflates the denominator relative to "circulating supply"
--   as Circle defines it, but is the right denominator for a *holder*
--   concentration view.
--
-- USDC (Ethereum) contract: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

WITH latest_day AS (
    SELECT MAX(day) AS d
    FROM stablecoins_evm.balances
    WHERE blockchain    = 'ethereum'
      AND token_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
),
holders AS (
    SELECT
        b.address,
        b.balance
    FROM stablecoins_evm.balances b
    JOIN latest_day ld ON b.day = ld.d
    WHERE b.blockchain    = 'ethereum'
      AND b.token_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
      AND b.balance > 0
),
ranked AS (
    SELECT
        address,
        balance,
        ROW_NUMBER() OVER (ORDER BY balance DESC) AS rn,
        SUM(balance) OVER ()                      AS total_balance
    FROM holders
)

SELECT
    CASE
        WHEN rn <= 10     THEN '01_top_10'
        WHEN rn <= 100    THEN '02_top_100'
        WHEN rn <= 1000   THEN '03_top_1000'
        WHEN rn <= 10000  THEN '04_top_10000'
        ELSE                    '05_rest'
    END                                AS bucket,
    COUNT(*)                           AS n_addresses,
    SUM(balance)                       AS bucket_balance,
    SUM(balance) / MAX(total_balance)  AS pct_of_supply
FROM ranked
GROUP BY 1
ORDER BY bucket;

-- Dashboard ideas once verified:
--   * column chart: pct_of_supply by bucket (the headline concentration story)
--   * companion query stablecoin_top_holders.sql lists the actual top-10
--     wallets so a reader can sanity-check who the concentration is in
-- Iterate via the Dune MCP, then record the published URL in dashboards.md.
