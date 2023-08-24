{{ config(
        alias='erc721_day'
        )
}}

WITH hours AS (
  SELECT
    TIMESTAMP_ADD(
      TIMESTAMP '2015-01-01 00:00:00 UTC', 
      INTERVAL x HOUR
    ) AS `hour`
  FROM (
    SELECT row_number() OVER () - 1 AS x
    FROM (
      SELECT NULL
      FROM UNNEST(GENERATE_ARRAY(1, TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), TIMESTAMP '2015-01-01 00:00:00 UTC', HOUR), 1)) -- generate enough numbers
    )
  )
)

, daily_balances as
 (SELECT
    b.wallet_address,
    b.token_address,
    b.tokenId,
    b.day,
    b.amount, 
    lead(b.day, 1, CURRENT_TIMESTAMP()) OVER (PARTITION BY b.wallet_address, b.token_address, b.tokenId ORDER BY `day`) AS next_day
FROM {{ ref('transfers_ethereum_erc721_rolling_day') }} b
LEFT JOIN {{ ref('balances_ethereum_erc721_noncompliant') }}  as nc
    ON b.token_address = nc.token_address
WHERE nc.token_address IS NULL 
)

SELECT 
    'ethereum' as blockchain,
    d.day,
    b.wallet_address,
    b.token_address,
    b.tokenId,
    nft_tokens.name as collection
FROM daily_balances b
INNER JOIN days d ON b.day <= d.day AND d.day < b.next_day
LEFT JOIN {{ ref('tokens_nft') }} nft_tokens ON nft_tokens.contract_address = b.token_address
AND nft_tokens.blockchain = 'ethereum'
where b.amount = 1