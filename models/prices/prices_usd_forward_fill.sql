{{ config(
        schema='prices',
        alias ='usd_forward_fill'
        )
}}

-- how much time we look back, anything before is considered finalized, anything after is forward filled.
-- we could decrease this to optimize query performance but it's a tradeoff with resiliency to lateness.
{%- set lookback_interval = '2 day' %}


WITH
  finalized as (
    select *
    FROM {{ source('prices', 'usd') }}
    where minute <= CURRENT_TIMESTAMP() - interval {{lookback_interval}}
)

, unfinalized as (
    select *,
        lead(minute) over (partition by blockchain,contract_address,decimals,symbol order by minute asc) as next_update_minute
    FROM {{ source('prices', 'usd') }}
    where minute > CURRENT_TIMESTAMP() - interval {{lookback_interval}}
)

, timeseries AS (
    SELECT timestamp as minute
    FROM UNNEST(
        GENERATE_TIMESTAMP_ARRAY(
            TIMESTAMP_SUB(
                TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MINUTE),
                INTERVAL {{lookback_interval}}
            ),
            TIMESTAMP_TRUNC(CURRENT_TIMESTAMP(), MINUTE),
            INTERVAL 60 SECOND  -- Here, 60 seconds is equivalent to 1 minute
        )
    ) AS timestamp
)


, forward_fill as (
    select
    t.minute
    ,blockchain
    ,contract_address
    ,decimals
    ,symbol
    ,price
    from timeseries t
    left join unfinalized p
    ON t.minute >= p.minute and (p.next_update_minute is null OR t.minute < p.next_update_minute) -- perform forward fill
)

SELECT
    minute
    ,blockchain
    ,contract_address
    ,decimals
    ,symbol
    ,price
FROM finalized
UNION ALL
SELECT
    minute
    ,blockchain
    ,contract_address
    ,decimals
    ,symbol
    ,price
FROM forward_fill