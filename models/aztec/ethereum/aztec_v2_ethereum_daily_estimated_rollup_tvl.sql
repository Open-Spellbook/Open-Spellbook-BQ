{{ config(
    schema = 'aztec_v2_ethereum',
    alias = 'daily_estimated_rollup_tvl'
    )
}}

{% set first_transfer_date = '2022-06-06' %}

WITH

rollup_balance_changes as (
  select TIMESTAMP_TRUNC(t.evt_block_time, day) as date
    , t.symbol
    , t.contract_address as token_address
    , sum(case when t.from_type = 'Rollup' then -1 * value_norm when t.to_type = 'Rollup' then value_norm else 0 end) as net_value_norm
  from {{ref('aztec_v2_ethereum_rollupbridge_transfers')}} t
  where t.from_type = 'Rollup' or t.to_type = 'Rollup'
  group by 1,2,3
)

, token_balances as (
  select date
    , symbol
    , token_address
    , sum(net_value_norm) over (partition by symbol,token_address order by date asc rows between unbounded preceding and current row) as balance
    , lead(date, 1) over (partition by token_address order by date) as next_date
  from rollup_balance_changes
)

, day_series AS (
  SELECT TIMESTAMP(date) AS date
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2022-06-06', CURRENT_DATE(), INTERVAL 1 DAY)) AS date
)

, token_balances_filled AS (
  SELECT d.date
    , b.symbol
    , b.token_address
    , b.balance
  FROM day_series d
  INNER JOIN token_balances b
        ON d.date >= b.date
        AND d.date < COALESCE(b.next_date, TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 1 SECOND)) 
        -- Adding 1 second to the current timestamp
)
, token_addresses as (
    SELECT 
        DISTINCT(token_address) as token_address FROM rollup_balance_changes
) 

, token_prices_token as (
    SELECT 
        TIMESTAMP_TRUNC(p.minute, day) AS `day`, 
        p.contract_address as token_address, 
        p.symbol, 
        AVG(p.price) as price
    FROM token_addresses t
    LEFT JOIN {{ source('prices', 'usd') }} p 
    ON p.contract_address = t.token_address
    WHERE p.minute >= '{{first_transfer_date}}'
    AND p.blockchain = 'ethereum'
    GROUP BY 1, 2, 3 
)

, token_prices_eth as (
    SELECT 
        TIMESTAMP_TRUNC(p.minute, day) AS `day`, 
        AVG(p.price) as price,
        1 as price_eth
    FROM 
    {{ source('prices', 'usd') }} p 
    WHERE p.minute >= '{{first_transfer_date}}'
    AND p.blockchain = 'ethereum'
    AND p.symbol = 'WETH'
    GROUP BY 1, 3 
)

, token_prices as (
    SELECT 
        tt.day, 
        tt.token_address,
        tt.symbol,
        tt.price as price_usd, 
        tt.price/te.price as price_eth,
        te.price as eth_price 
    FROM 
    token_prices_token tt 
    INNER JOIN 
    token_prices_eth te 
        ON tt.day = te.day 
)
, token_tvls as (
  select b.date
    , b.symbol
    , b.token_address
    , b.balance
    , b.balance * COALESCE(p.price_usd, bb.price) as tvl_usd
    , b.balance * COALESCE(p.price_eth, bb.price_eth) as tvl_eth
  FROM token_balances_filled b
  LEFT join token_prices p on b.date = p.day and b.token_address = p.token_address AND b.token_address != '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' 
  LEFT JOIN token_prices_eth bb on b.date = bb.day AND b.token_address = '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' -- using this to get price for missing ETH token 
  
)
select * from token_tvls