{{ config(
        alias ='mints',
        post_hook='{{ expose_spells(\'["ethereum","solana"]\',
                                    "sector",
                                    "nft",
                                    \'["soispoke"]\') }}')
}}

SELECT *
FROM
(
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('opensea_mints') }} 
        UNION
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('magiceden_mints') }}
        UNION
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('looksrare_ethereum_mints') }}
        UNION
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('x2y2_ethereum_mints') }}
        UNION
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('element_mints') }}
        UNION
        SELECT
                blockchain,
                project,
                version,
                block_time,
                token_id,
                collection,
                amount_usd,
                token_standard,
                trade_type,
                number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                amount_raw,
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
        FROM {{ ref('foundation_ethereum_mints') }}
)