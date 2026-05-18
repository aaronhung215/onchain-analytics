-- eth_dex_volume.sql
-- Ethereum DEX volume by project, daily trend (last 90 days).
--
-- Source: dex.trades — cross-chain DEX spell, partitioned by
-- (blockchain, project, block_month). Schema verified via Dune MCP.
--
-- Cost notes:
--   * blockchain = 'ethereum'                   → prunes ~50 chains down to 1
--   * block_month >= trunc(today - 90d, month)  → prunes to ~4 monthly partitions
--   * block_time  >= now() - 90d                → trims the leading partition
--   * amount_usd IS NOT NULL                    → drops trades we couldn't price

WITH daily AS (
    SELECT
        block_date                           AS day,
        project                              AS dex,
        SUM(amount_usd)                      AS volume_usd,
        COUNT(*)                             AS trades
    FROM dex.trades
    WHERE blockchain = 'ethereum'
      AND block_month >= date_trunc('month', CURRENT_DATE - INTERVAL '90' DAY)
      AND block_time  >= CURRENT_TIMESTAMP - INTERVAL '90' DAY
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
