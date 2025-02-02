{{ config(
    alias = 'repay'
) }}

SELECT
r.evt_block_number AS block_number,
r.evt_block_time AS block_time,
r.evt_tx_hash AS tx_hash,
r.evt_index AS `index`,
CAST(r.contract_address AS STRING) AS contract_address,
r.borrower,
i.symbol,
i.underlying_symbol,
i.underlying_token_address AS underlying_address,
CAST(r.repayAmount AS FLOAT64) / power(10,i.underlying_decimals) AS repay_amount,
CAST(r.repayAmount AS FLOAT64) / power(10,i.underlying_decimals)*p.price AS repay_usd
FROM {{ source('ironbank_optimism', 'CErc20Delegator_evt_RepayBorrow') }} r
LEFT JOIN {{ ref('ironbank_optimism_itokens') }} i ON i.contract_address = CAST(r.contract_address AS STRING)
LEFT JOIN {{ source('prices', 'usd') }} p ON p.minute = TIMESTAMP_TRUNC(r.evt_block_time, minute) AND CAST(p.contract_address AS STRING) = i.underlying_token_address AND p.blockchain = 'optimism'