 {{
  config(
        alias='fees')
}}

SELECT blockchain,
project,
version,
block_time,
token_id,
collection,
platform_fee_amount_raw,
platform_fee_amount,
platform_fee_amount_usd,
CAST(platform_fee_percentage AS FLOAT64) AS platform_fee_percentage,
royalty_fee_amount_raw,
royalty_fee_amount,
royalty_fee_amount_usd,
CAST(royalty_fee_percentage AS FLOAT64) AS royalty_fee_percentage,
royalty_fee_receive_address,
royalty_fee_currency_symbol,
token_standard,
trade_type,
CAST(number_of_items AS BIGNUMERIC) AS number_of_items,
trade_category,
evt_type,
seller,
buyer,
nft_contract_address,
project_contract_address,
aggregator_name,
aggregator_address,
block_number,
tx_hash,
tx_from,
tx_to,
unique_trade_id
FROM {{ ref('superrare_ethereum_events') }}