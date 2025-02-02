{{ config(
    alias = 'events',
    partition_by = {"field": "block_date"},
    materialized = 'view',
            unique_key = ['block_date', 'unique_trade_id'])
}}

{% set project_start_date = '2022-10-18' %}
{% set seaport_usage_start_date = '2023-01-25' %}


SELECT
    'ethereum' AS blockchain
    , 'blur' AS project
    , 'v1' AS version
    , CAST(TIMESTAMP_TRUNC(bm.evt_block_time, day) AS timestamp) AS block_date
    , CAST(bm.evt_block_time AS timestamp) AS block_time
    , CAST(bm.evt_block_number AS FLOAT64) AS block_number
    , CAST(JSON_EXTRACT_SCALAR(bm.sell, '$.tokenId') AS string) AS token_id
    , nft.standard AS token_standard
    , nft.name AS collection
    , CASE WHEN CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.amount') as FLOAT64)=1 THEN 'Single Item Trade'
        ELSE 'Bundle Trade'
        END AS trade_type
    , CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.amount') AS BIGNUMERIC) AS number_of_items
    , 'Trade' AS evt_type
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.sell, '$.trader') = agg.contract_address THEN et.from ELSE JSON_EXTRACT_SCALAR(bm.sell, '$.trader') END AS seller
    ,CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.trader') = agg.contract_address THEN et.from ELSE JSON_EXTRACT_SCALAR(bm.buy, '$.trader') END AS buyer
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.matchingPolicy') IN ('0x00000000006411739da1c40b106f8511de5d1fac', '0x0000000000dab4a563819e8fd93dba3b25bc3495') THEN 'Buy'
        WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.matchingPolicy') IN ('0x0000000000b92d5d043faf7cecf7e2ee6aaed232') THEN 'Offer Accepted'
        WHEN et.from=JSON_EXTRACT_SCALAR(bm.buy, '$.trader') THEN 'Buy'
        WHEN et.from=JSON_EXTRACT_SCALAR(bm.sell, '$.trader') THEN 'Offer Accepted'
        ELSE 'Unknown'
        END AS trade_category
    , CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') AS BIGNUMERIC) AS amount_raw
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64) / power(10,18)
        ELSE CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64) / POWER(10, pu.decimals)
        END AS amount_original
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN pu.price * CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64) / POWER(10, 18) 
        ELSE pu.price * CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64)/POWER(10, pu.decimals)
        END AS amount_usd
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN 'ETH'
        ELSE pu.symbol
        END AS currency_symbol
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
        ELSE JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken')
        END AS currency_contract
    , bm.contract_address AS project_contract_address
    , JSON_EXTRACT_SCALAR(bm.buy, '$.collection') AS nft_contract_address
    , coalesce(agg_m.aggregator_name, agg.name) AS aggregator_name
    , agg.contract_address AS aggregator_address
    , bm.evt_tx_hash AS tx_hash
    , et.from AS tx_from
    , et.to AS tx_to
    , CAST(0 AS FLOAT64) AS platform_fee_amount_raw
    , CAST(0 AS FLOAT64) AS platform_fee_amount
    , CAST(0 AS FLOAT64) AS platform_fee_amount_usd
    , CAST(0 AS FLOAT64) AS platform_fee_percentage
    , CAST(COALESCE(CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') AS FLOAT64) * CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate') as FLOAT64)/10000, 0) AS FLOAT64) AS royalty_fee_amount_raw
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN COALESCE(CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64)/POWER(10, 18)*CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate')AS FLOAT64)/10000, 0)
        ELSE CAST(COALESCE(CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64)/POWER(10, pu.decimals)*CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate') as FLOAT64)/10000, 0) AS FLOAT64)
        END AS royalty_fee_amount
    , CASE WHEN JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN COALESCE(pu.price*CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64)/POWER(10, 18)*CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate') as FLOAT64) /10000, 0)
        ELSE COALESCE(pu.price*CAST(JSON_EXTRACT_SCALAR(bm.buy, '$.price') as FLOAT64)/POWER(10, pu.decimals)*CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate') as FLOAT64)/10000, 0)
        END AS royalty_fee_amount_usd
    , COALESCE(CAST(JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.rate') as FLOAT64)/100, 0) AS royalty_fee_percentage
    , JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.recipient') AS royalty_fee_receive_address
    , CASE WHEN JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.recipient') IS NOT NULL AND JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken') IN ('0x0000000000000000000000000000000000000000', '0x0000000000a39bb272e79075ade125fd351887ac') THEN 'ETH'
        WHEN JSON_EXTRACT_SCALAR(JSON_EXTRACT_SCALAR(bm.sell, '$.fees[0]'), '$.recipient') IS NOT NULL THEN pu.symbol
        END AS royalty_fee_currency_symbol
    ,  CAST('ethereum-blur-v1-' || bm.evt_block_number || '-' || bm.evt_tx_hash || '-' || bm.evt_index AS string) AS unique_trade_id
    FROM {{ source('blur_ethereum','BlurExchange_evt_OrdersMatched') }} bm
JOIN {{ source('ethereum','transactions') }} et ON et.block_number=bm.evt_block_number
    AND et.hash=bm.evt_tx_hash
    {% if not is_incremental() %}
    AND et.block_time >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND et.block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ ref('nft_ethereum_aggregators') }} agg ON agg.contract_address=et.to
LEFT JOIN {{ ref('nft_ethereum_aggregators_markers') }} agg_m
    ON RIGHT(et.data, agg_m.hash_marker_size) = agg_m.hash_marker
LEFT JOIN {{ source('prices','usd') }} pu ON pu.blockchain='ethereum'
    AND pu.minute=TIMESTAMP_TRUNC(bm.evt_block_time, minute)
    AND (pu.contract_address=JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken')
        OR (pu.contract_address='0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2' AND JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken')='0x0000000000000000000000000000000000000000')
        OR (pu.contract_address='0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2' AND JSON_EXTRACT_SCALAR(bm.buy, '$.paymentToken')='0x0000000000a39bb272e79075ade125fd351887ac'))
    {% if not is_incremental() %}
    AND pu.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND pu.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ ref('tokens_ethereum_nft') }} nft ON JSON_EXTRACT_SCALAR(bm.buy, '$.collection')=nft.contract_address
{% if is_incremental() %}
WHERE bm.evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
{% endif %}

UNION ALL


SELECT
    'ethereum' AS blockchain
    , 'blur' AS project
    , 'v1' AS version
    , CAST(TIMESTAMP_TRUNC(s.evt_block_time, day) AS timestamp) AS block_date
    , CAST(s.evt_block_time AS timestamp) AS block_time
    , CAST(s.evt_block_number AS FLOAT64) AS block_number
    , CAST(JSON_EXTRACT_SCALAR(s.offer[0], '$.identifier') AS string) AS token_id
    , nft_tok.standard AS token_standard
    , nft_tok.name AS collection
    , CASE WHEN CAST(JSON_EXTRACT_SCALAR(s.offer[0], '$.amount') as FLOAT64)=1 THEN 'Single Item Trade' ELSE 'Bundle Trade' END AS trade_type
    , CAST(JSON_EXTRACT_SCALAR(s.offer[0], '$.amount') AS BIGNUMERIC) AS number_of_items
    , 'Trade' AS evt_type
    , s.offerer AS seller
    , s.recipient AS buyer
    , 'Buy' AS trade_category
    , CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') as BIGNUMERIC)+CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS BIGNUMERIC) AS amount_raw
    , CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') as BIGNUMERIC)+CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') as BIGNUMERIC)/POWER(10, 18) AS amount_original
    , pu.price*(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') as FLOAT64) + CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64)/POWER(10, 18)) AS amount_usd
    , CASE WHEN JSON_EXTRACT_SCALAR(s.consideration[0], '$.token')='0x0000000000000000000000000000000000000000' THEN 'ETH' ELSE currency_tok.symbol END AS currency_symbol
    , JSON_EXTRACT_SCALAR(s.consideration[0], '$.token') AS currency_contract
    , s.contract_address AS project_contract_address
    , JSON_EXTRACT_SCALAR(s.offer[0], '$.token') AS nft_contract_address
    , CAST(NULL AS string) AS aggregator_name
    , CAST(NULL AS string) AS aggregator_address
    , s.evt_tx_hash AS tx_hash
    , tx.from AS tx_from
    , tx.to AS tx_to
    , CAST(0 AS FLOAT64) AS platform_fee_amount_raw
    , CAST(0 AS FLOAT64) AS platform_fee_amount
    , CAST(0 AS FLOAT64) AS platform_fee_amount_usd
    , CAST(0 AS FLOAT64) AS platform_fee_percentage
    , LEAST(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') AS FLOAT64), CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64)) AS royalty_fee_amount_raw
    , LEAST(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') AS FLOAT64), CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64))/POWER(10, 18) AS royalty_fee_amount
    , pu.price*LEAST(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') AS FLOAT64), CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64))/POWER(10, 18) AS royalty_fee_amount_usd
    , 100.0*LEAST(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') AS FLOAT64), CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64))
        /CAST(CAST(JSON_EXTRACT_SCALAR(s.consideration[0], '$.amount') AS FLOAT64)+CAST(JSON_EXTRACT_SCALAR(s.consideration[1], '$.amount') AS FLOAT64) AS BIGNUMERIC) AS royalty_fee_percentage
    , CASE WHEN JSON_EXTRACT_SCALAR(s.consideration[0], '$.token')='0x0000000000000000000000000000000000000000' THEN 'ETH' ELSE currency_tok.symbol END AS royalty_fee_currency_symbol
    , CASE WHEN JSON_EXTRACT_SCALAR(s.consideration[0], '$.recipient')!=s.recipient THEN JSON_EXTRACT_SCALAR(s.consideration[0], '$.recipient')
        ELSE JSON_EXTRACT_SCALAR(s.consideration[1], '$.recipient')
        END AS royalty_fee_receive_address
    , CAST('ethereum-blur-v1-' || s.evt_block_number || '-' || s.evt_tx_hash || '-' || s.evt_index AS string) AS unique_trade_id
FROM {{ source('seaport_ethereum','Seaport_evt_OrderFulfilled') }} s
INNER JOIN {{ source('ethereum', 'transactions') }} tx ON tx.block_number=s.evt_block_number
    AND tx.hash=s.evt_tx_hash
    {% if is_incremental() %}
    AND tx.block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
    {% if not is_incremental() %}
    AND tx.block_time >= '{{seaport_usage_start_date}}'
    {% endif %}
LEFT JOIN {{ ref('tokens_ethereum_nft') }} nft_tok ON nft_tok.contract_address=JSON_EXTRACT_SCALAR(s.offer[0], '$.token')
LEFT JOIN {{ ref('tokens_ethereum_erc20') }} currency_tok ON currency_tok.contract_address=JSON_EXTRACT_SCALAR(s.consideration[0], '$.token')
LEFT JOIN {{ ref('prices_usd_forward_fill') }} pu ON ((pu.contract_address=JSON_EXTRACT_SCALAR(s.consideration[0], '$.token') AND pu.blockchain='ethereum')
        OR (JSON_EXTRACT_SCALAR(s.consideration[0], '$.token')='0x0000000000000000000000000000000000000000'  AND pu.blockchain IS NULL AND pu.contract_address IS NULL AND pu.symbol='ETH'))
    AND pu.minute=TIMESTAMP_TRUNC(s.evt_block_time, minute)
    {% if is_incremental() %}
    AND pu.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
    {% if not is_incremental() %}
    AND pu.minute >= '{{seaport_usage_start_date}}'
    {% endif %}
WHERE s.zone='0x0000000000d80cfcb8dfcd8b2c4fd9c813482938'
{% if is_incremental() %}
AND s.evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
{% endif %}
{% if not is_incremental() %}
AND s.evt_block_time >= '{{seaport_usage_start_date}}'
{% endif %}