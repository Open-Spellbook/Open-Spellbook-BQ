 {{
  config(
        alias='trades')
}}

SELECT
      blockchain,
      project,
      version,
      block_time,
      CAST(token_id AS STRING) AS token_id,
      collection,
      amount_usd,
      token_standard,
      trade_type,
      CAST(number_of_items AS BIGNUMERIC) AS number_of_items,
      trade_category,
      evt_type,
      seller,
      buyer,
      amount_original,
      CAST(amount_raw AS BIGNUMERIC) AS amount_raw,
      currency_symbol,
      currency_contract,
      nft_contract_address,
      project_contract_address,
      aggregator_name,
      aggregator_address,
      tx_hash,
      block_number,
      tx_from,
      tx_to,
      unique_trade_id
FROM {{ ref('sudoswap_ethereum_events') }}
WHERE evt_type = 'Trade'