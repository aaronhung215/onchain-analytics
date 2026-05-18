-- eth_dex_weekly_share.sql
-- Ethereum DEX weekly market share, top-7 + 'other' bucket, last 90 days.
--
-- Source: dex.trades — cross-chain DEX spell, partitioned by
-- (blockchain, project, block_month). Schema verified via Dune MCP.
--
-- Why top-7 + other:
--   90d output is ~25-30 projects; the long tail is < 0.5% share each and
--   washes out the chart. Top-7 covers ~96% of volume; the rest fold into
--   'other' so the stacked chart stays readable.
--
-- Output (one row per week × bucket):
--   week         — start of ISO week (Mon, UTC)
--   dex          — project name, or 'other' for ranks 8+
--   volume_usd   — sum of amount_usd for that week × bucket
--   share        — volume_usd / sum(volume_usd) within the same week
--
-- Cost notes (mirrors eth_dex_volume.sql):
--   blockchain = 'ethereum'                    → prunes ~50 chains to 1
--   block_month >= trunc(today - 90d, month)   → prunes to ~4 monthly partitions
--   block_time  >= now() - 90d                 → trims the leading partition
--   amount_usd IS NOT NULL                     → drops trades we couldn't price
--
-- Reads dex.trades twice via per_week_dex → rank_90d. A single pass is possible
-- but window-functions over a non-aggregated scan cost more on this dataset.

WITH per_week_dex AS (
    SELECT
        date_trunc('week', block_time)  AS week,
        project,
        SUM(amount_usd)                 AS volume_usd
    FROM dex.trades
    WHERE blockchain = 'ethereum'
      AND block_month >= date_trunc('month', CURRENT_DATE - INTERVAL '90' DAY)
      AND block_time  >= CURRENT_TIMESTAMP - INTERVAL '90' DAY
      AND amount_usd IS NOT NULL
    GROUP BY 1, 2
),
rank_90d AS (
    SELECT
        project,
        SUM(volume_usd)                                       AS volume_90d,
        ROW_NUMBER() OVER (ORDER BY SUM(volume_usd) DESC)     AS rnk
    FROM per_week_dex
    GROUP BY 1
),
bucketed AS (
    SELECT
        p.week                                                AS week,
        CASE WHEN r.rnk <= 7 THEN p.project ELSE 'other' END  AS dex,
        SUM(p.volume_usd)                                     AS volume_usd
    FROM per_week_dex p
    JOIN rank_90d     r ON p.project = r.project
    GROUP BY 1, 2
),
week_totals AS (
    SELECT week, SUM(volume_usd) AS weekly_total
    FROM bucketed
    GROUP BY 1
)

SELECT
    b.week,
    b.dex,
    b.volume_usd,
    b.volume_usd / wt.weekly_total                            AS share
FROM bucketed    b
JOIN week_totals wt ON b.week = wt.week
ORDER BY b.week, b.volume_usd DESC;

-- Dashboard usage:
--   * stacked area:   x = week, y = share, color = dex   (main chart)
--   * stacked bars:   x = week, y = volume_usd, color = dex (volume-magnitude view)
--   * line + table:   Uniswap share over time, with Balancer overlay for the
--                     "consolidation" narrative
-- Filter out the trailing partial week in the dashboard layer (it under-counts).
