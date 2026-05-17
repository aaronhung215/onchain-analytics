-- eth_dex_volume.sql
-- Ethereum DEX volume by project, daily trend.
--
-- ⚠️ v0 SCAFFOLD — NOT YET RUN/VERIFIED on Dune.
-- Encodes the intended table + pattern. Run via the Dune MCP, check column
-- names against the live `dex.trades` schema, and correct before trusting
-- results or building the dashboard. Column names below are the common ones
-- but MUST be confirmed against the current schema.
--
-- Conventions: filter by block_time first; use the decoded `dex.trades`
-- abstraction (not raw logs); amount_usd is already USD-normalized there.

WITH daily AS (
    SELECT
        date_trunc('day', block_time)        AS day,
        project                              AS dex,
        SUM(amount_usd)                      AS volume_usd,
        COUNT(*)                             AS trades
    FROM dex.trades
    WHERE blockchain = 'ethereum'
      AND block_time >= NOW() - INTERVAL '90' DAY   -- bound the scan; widen later if needed
      AND amount_usd IS NOT NULL
    GROUP BY 1, 2
)

SELECT
    day,
    dex,
    volume_usd,
    trades
FROM daily
ORDER BY day DESC, volume_usd DESC;

-- Dashboard ideas once verified:
--   * stacked area: volume_usd by dex over day
--   * single-stat: total 30d volume
--   * bar: top dex by 7d volume
-- Iterate via the Dune MCP, then record the published URL in dashboards.md.
