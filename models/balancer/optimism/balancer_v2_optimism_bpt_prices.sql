{{
    config(
        schema = 'balancer_v2_optimism',
        alias='bpt_prices'
    )
}}

WITH bpt_trades AS (
    SELECT
        block_time,
        bpt_address,
        bpt_amount_raw,
        bpt_amount_raw / POWER(10, COALESCE(erc20a.decimals, 18)) AS bpt_amount,
        token_amount_raw,
        token_amount_raw / POWER(10, erc20b.decimals) AS token_amount,
        p.price * token_amount_raw / POWER(10, erc20b.decimals) AS usd_amount
    FROM (
        SELECT
            t.evt_block_time AS block_time,
            CASE 
                WHEN t.tokenIn = SUBSTRING(t.poolId, 0, 42) THEN t.tokenIn
                ELSE t.tokenOut
            END AS bpt_address,
            CASE 
                WHEN t.tokenIn = SUBSTRING(t.poolId, 0, 42) THEN t.amountIn
                ELSE t.amountOut
            END AS bpt_amount_raw,
            CASE 
                WHEN t.tokenIn = SUBSTRING(t.poolId, 0, 42) THEN t.tokenOut
                ELSE t.tokenIn
            END AS token_address,
            CASE
                WHEN t.tokenIn = SUBSTRING(t.poolId, 0, 42) THEN t.amountOut
                ELSE t.amountIn
            END AS token_amount_raw
        FROM {{ source('balancer_v2_optimism', 'Vault_evt_Swap') }} t
        WHERE t.tokenIn IS NULL AND t.tokenIn = SUBSTRING(t.poolId, 0, 42)
        OR t.tokenOut = SUBSTRING(t.poolId, 0, 42)
    ) dexs
    LEFT JOIN {{ ref('tokens_erc20') }} erc20a ON erc20a.contract_address = dexs.bpt_address
    AND erc20a.blockchain = "optimism"
    JOIN {{ ref('tokens_erc20') }}  erc20b ON erc20b.contract_address = dexs.token_address
    AND erc20b.blockchain = "optimism"
    LEFT JOIN {{ source('prices', 'usd') }} p ON p.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p.contract_address = dexs.token_address AND p.blockchain = "optimism"
),

bpt_estimated_prices AS (
    SELECT
        block_time,
        bpt_address,
        usd_amount / bpt_amount AS price
    FROM
        bpt_trades
)

SELECT
    TIMESTAMP_TRUNC(block_time, hour) AS `hour`,
    bpt_address AS contract_address,
    PERCENTILE(price, 0.5) AS median_price
FROM bpt_estimated_prices
GROUP BY 1, 2