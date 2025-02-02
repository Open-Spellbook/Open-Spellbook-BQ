{{ config(
        alias ='events'
)
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
                CAST(number_of_items AS BIGNUMERIC) number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                CAST(amount_raw AS BIGNUMERIC) amount_raw,
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
                platform_fee_amount_raw,
                platform_fee_amount,
                platform_fee_amount_usd,
                CAST(platform_fee_percentage AS FLOAT64) platform_fee_percentage,
                royalty_fee_amount_raw,
                royalty_fee_amount,
                royalty_fee_amount_usd,
                CAST(royalty_fee_percentage AS FLOAT64) royalty_fee_percentage,
                royalty_fee_receive_address,
                royalty_fee_currency_symbol,
                unique_trade_id
        FROM {{ ref('opensea_ethereum_events') }}
        UNION ALL
        SELECT
                blockchain,
                project,
                version,
                block_time,
                CAST(NULL AS STRING) as token_id,
                CAST(NULL AS STRING) as collection,
                amount_usd,
                token_standard,
                CAST(NULL AS STRING) as trade_type,
                CAST(NULL AS BIGNUMERIC) as number_of_items,
                CAST(NULL AS STRING) as trade_category,
                evt_type,
                CAST(NULL AS STRING) as seller,
                CAST(NULL AS STRING) as buyer,
                amount_original,
                CAST(amount_raw AS BIGNUMERIC) AS amount_raw,
                currency_symbol,
                currency_contract,
                CAST(NULL AS STRING) as nft_contract_address,
                project_contract_address,
                CAST(NULL AS STRING) as aggregator_name,
                CAST(NULL AS STRING) as aggregator_address,
                tx_hash,
                block_number,
                CAST(NULL AS STRING) as tx_from,
                CAST(NULL AS STRING) as tx_to,
                CAST(NULL AS FLOAT64) AS platform_fee_amount_raw,
                CAST(NULL AS FLOAT64) AS platform_fee_amount,
                CAST(NULL AS FLOAT64) AS platform_fee_amount_usd,
                CAST(NULL AS FLOAT64) as platform_fee_percentage,
                CAST(NULL AS FLOAT64) as royalty_fee_amount_raw,
                CAST(NULL AS FLOAT64) as royalty_fee_amount,
                CAST(NULL AS FLOAT64) as royalty_fee_amount_usd,
                CAST(NULL AS FLOAT64) as royalty_fee_percentage,
                CAST(NULL AS STRING) as royalty_fee_receive_address,
                CAST(NULL AS STRING) as royalty_fee_currency_symbol,
                unique_trade_id
        FROM {{ ref('opensea_solana_events') }}
        UNION ALL
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
                CAST(number_of_items AS BIGNUMERIC) number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                CAST(amount_raw AS BIGNUMERIC) amount_raw,
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
                platform_fee_amount_raw,
                platform_fee_amount,
                platform_fee_amount_usd,
                CAST(platform_fee_percentage AS FLOAT64) platform_fee_percentage,
                royalty_fee_amount_raw,
                royalty_fee_amount,
                royalty_fee_amount_usd,
                CAST(royalty_fee_percentage AS FLOAT64) royalty_fee_percentage,
                royalty_fee_receive_address,
                royalty_fee_currency_symbol,
                unique_trade_id
        FROM {{ ref('opensea_optimism_events') }}
        UNION ALL
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
                CAST(number_of_items AS BIGNUMERIC) number_of_items,
                trade_category,
                evt_type,
                seller,
                buyer,
                amount_original,
                CAST(amount_raw AS BIGNUMERIC) amount_raw,
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
                platform_fee_amount_raw,
                platform_fee_amount,
                platform_fee_amount_usd,
                platform_fee_percentage,
                royalty_fee_amount_raw,
                royalty_fee_amount,
                royalty_fee_amount_usd,
                royalty_fee_percentage,
                royalty_fee_receive_address,
                royalty_fee_currency_symbol,
                unique_trade_id
        FROM {{ ref('opensea_polygon_events') }}
)