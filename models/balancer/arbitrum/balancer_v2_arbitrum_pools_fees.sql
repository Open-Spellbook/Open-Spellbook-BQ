{{
    config(
        schema = 'balancer_v2_arbitrum',
        alias='pools_fees',
        materialized = 'view',
                        unique_key = ['block_number', 'tx_hash', 'index']
    ) 
}}

{% set event_signature = '0xa9ba3ffe0b6c366b81232caab38605a0699ad5398d6cce76f91ee809e322dafc' %}
{% set project_start_date = '2021-08-26' %}

WITH registered_pools AS (
    SELECT DISTINCT
        `poolAddress` AS pool_address
    FROM
        {{ source ('balancer_v2_arbitrum', 'Vault_evt_PoolRegistered') }}
)
SELECT
    logs.contract_address,
    logs.tx_hash,
    logs.tx_index,
    logs.index,
    logs.block_time,
    logs.block_number,
    udfs.bytea2numeric_v3 (SUBSTR(logs.data, 32, 64)) * 1 AS swap_fee_percentage
FROM
    {{ source ('arbitrum', 'logs') }}
    INNER JOIN registered_pools ON registered_pools.pool_address = logs.contract_address
WHERE logs.topic1 IS NULL AND logs.topic1 = '{{ event_signature }}'
    {% if not is_incremental() %}
    AND logs.block_time >= '{{ project_start_date }}'
    {% endif %}
    {% if is_incremental() %}
    AND logs.block_time >= DATE_TRUNC('day', CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}