-- stablecoin_holders.sql
-- Stablecoin holder concentration: top-N holders' share of circulating balance.
-- Default token: USDC on Ethereum (swap the address to analyze another).
--
-- ⚠️ v0 SCAFFOLD — NOT YET RUN/VERIFIED on Dune.
-- This computes current balances by replaying transfers (in - out). For a
-- large stablecoin this can be heavy; when iterating via the Dune MCP,
-- consider: (a) a balances/erc20 abstraction if available on the connected
-- account, (b) tighter time bounds, (c) a snapshot at a fixed block.
-- Confirm table + column names against the live schema before trusting output.
--
-- USDC (Ethereum) contract: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

WITH transfers AS (
    SELECT "from" AS addr, -CAST(value AS int256) AS delta
    FROM erc20_ethereum.evt_Transfer
    WHERE contract_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
      AND evt_block_time >= NOW() - INTERVAL '365' DAY   -- bound; adjust for full history
    UNION ALL
    SELECT "to" AS addr, CAST(value AS int256) AS delta
    FROM erc20_ethereum.evt_Transfer
    WHERE contract_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
      AND evt_block_time >= NOW() - INTERVAL '365' DAY
),

balances AS (
    SELECT addr, SUM(delta) / 1e6 AS balance   -- USDC has 6 decimals
    FROM transfers
    GROUP BY addr
    HAVING SUM(delta) > 0
),

ranked AS (
    SELECT
        addr,
        balance,
        ROW_NUMBER() OVER (ORDER BY balance DESC) AS rn,
        SUM(balance) OVER ()                      AS total_supply_proxy
    FROM balances
)

SELECT
    CASE
        WHEN rn <= 10  THEN 'top_10'
        WHEN rn <= 100 THEN 'top_100'
        ELSE 'rest'
    END                                                   AS bucket,
    SUM(balance)                                          AS bucket_balance,
    SUM(balance) / MAX(total_supply_proxy) * 100          AS pct_of_supply
FROM ranked
GROUP BY 1
ORDER BY bucket_balance DESC;

-- Dashboard ideas once verified:
--   * pie/bar: top_10 vs top_100 vs rest share of supply
--   * line: top_10 concentration % over time (parameterize the snapshot day)
-- Note: the time-bounded transfer replay is an approximation of true balance;
-- state this limitation in notes/ and the dashboard description (honesty rule).
