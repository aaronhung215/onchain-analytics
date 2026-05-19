-- stablecoin_top_holders.sql
-- Top-10 USDC holders on Ethereum at the latest available snapshot, with
-- owner labels where Dune's labels.owner_addresses has coverage.
--
-- Source:
--   stablecoins_evm.balances    — daily per-holder snapshot, USD-priced
--   labels.owner_addresses      — multi-chain owner/custody labels
--
-- Labels caveat:
--   labels.owner_addresses covers a subset of well-known addresses (notably
--   centralised exchanges). Many of the top-N wallets — Circle treasury,
--   bridge escrows, market makers — won't have a label entry here and will
--   render as '(unlabeled)'. That's an artefact of label coverage, not of
--   the underlying data. A future iteration could join more label tables
--   (e.g. labels.ens) or maintain a small static lookup for known unlabelled
--   whales.
--
-- USDC (Ethereum) contract: 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

WITH latest_day AS (
    SELECT MAX(day) AS d
    FROM stablecoins_evm.balances
    WHERE blockchain    = 'ethereum'
      AND token_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
),
top10 AS (
    SELECT
        b.address,
        b.balance,
        ROW_NUMBER() OVER (ORDER BY b.balance DESC) AS rn
    FROM stablecoins_evm.balances b
    JOIN latest_day ld ON b.day = ld.d
    WHERE b.blockchain    = 'ethereum'
      AND b.token_address = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48
      AND b.balance > 0
    ORDER BY b.balance DESC
    LIMIT 10
),
labels_for_top10 AS (
    SELECT
        address,
        MIN(COALESCE(custody_owner, account_owner, contract_name, owner_key))
            AS owner_label
    FROM labels.owner_addresses
    WHERE blockchain = 'ethereum'
      AND address IN (SELECT address FROM top10)
    GROUP BY address
)

SELECT
    t.rn                                   AS rank,
    CAST(t.address AS VARCHAR)             AS address,
    t.balance                              AS usdc_balance,
    COALESCE(l.owner_label, '(unlabeled)') AS owner_label
FROM top10 t
LEFT JOIN labels_for_top10 l ON l.address = t.address
ORDER BY t.rn;

-- Dashboard usage: render as a table widget below the bucket-concentration
-- column chart. The two together tell the same story from different angles:
-- the buckets quantify "how concentrated", the table answers "in whose hands".
