{{ config
(
    alias ='trades',
    partition_by = {"field": "block_date"},
    materialized = 'view',
            unique_key = ['block_date', 'blockchain', 'project', 'version', 'tx_hash', 'evt_index', 'trace_address']
)
}}
    

{% set project_start_date = '2022-04-27' %}

WITH dexs as 
 (SELECT
            evt_block_time AS block_time
            ,'woofi' AS project
            ,'1' AS version
            ,from AS taker
            ,to AS maker
            ,fromAmount AS token_bought_amount_raw
            ,toAmount AS token_sold_amount_raw
            ,cast(NULL as FLOAT64) AS amount_usd
            ,fromToken AS token_bought_address
            ,toToken AS token_sold_address
            ,contract_address AS project_contract_address
            ,evt_tx_hash AS tx_hash
            ,'' AS trace_address
            ,evt_index
        FROM
            {{ source('woofi_avalanche_c', 'WooPP_evt_WooSwap')}}
        WHERE from <> '0x5aa6a4e96a9129562e2fc06660d07feddaaf7854' -- woorouter

        {% if is_incremental() %}
        AND evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}

        UNION ALL 

        SELECT
            evt_block_time AS block_time
            ,'woofi' AS project
            ,'1' AS version
            ,from AS taker
            ,to AS maker
            ,fromAmount AS token_bought_amount_raw
            ,toAmount AS token_sold_amount_raw
            ,cast(NULL as FLOAT64) AS amount_usd
            ,fromToken AS token_bought_address
            ,toToken AS token_sold_address
            ,contract_address AS project_contract_address
            ,evt_tx_hash AS tx_hash
            ,'' AS trace_address
            ,evt_index
        FROM
            {{ source('woofi_avalanche_c', 'WooRouterV2_evt_WooRouterSwap')}}

        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}


 )


SELECT
    'avalanche_c' AS blockchain
    ,project
    ,version
    ,SAFE_CAST(TIMESTAMP_TRUNC(dexs.block_time, DAY) AS date) AS block_date
    ,dexs.block_time
    ,erc20a.symbol AS token_bought_symbol
    ,erc20b.symbol AS token_sold_symbol
    ,case
        when lower(erc20a.symbol) > lower(erc20b.symbol) then concat(erc20b.symbol, '-', erc20a.symbol)
        else concat(erc20a.symbol, '-', erc20b.symbol)
    end as token_pair
    ,dexs.token_bought_amount_raw / power(10, erc20a.decimals) AS token_bought_amount
    ,dexs.token_sold_amount_raw / power(10, erc20b.decimals) AS token_sold_amount
    ,CAST(dexs.token_bought_amount_raw AS BIGNUMERIC) AS token_bought_amount_raw
    ,CAST(dexs.token_sold_amount_raw AS BIGNUMERIC) AS token_sold_amount_raw
    ,coalesce(
        dexs.amount_usd
        , (dexs.token_bought_amount_raw
            / power(10, (CASE dexs.token_bought_address
                             WHEN '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' THEN 18
                             ELSE p_bought.decimals
                END))
              )
            * (CASE dexs.token_bought_address
                   WHEN '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' THEN p_avx.price
                   ELSE p_bought.price
                END)
        , (dexs.token_sold_amount_raw
            / power(10, (CASE dexs.token_sold_address
                             WHEN '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' THEN 18
                             ELSE p_sold.decimals
                END))
              )
            * (CASE dexs.token_sold_address
                   WHEN '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee' THEN p_avx.price
                   ELSE p_sold.price
                END)
    ) as amount_usd
    ,dexs.token_bought_address
    ,dexs.token_sold_address
    ,coalesce(dexs.taker, tx.from) AS taker -- subqueries rely on this COALESCE to avoid redundant joins with the transactions table
    ,dexs.maker
    ,dexs.project_contract_address
    ,dexs.tx_hash
    ,tx.from AS tx_from
    ,tx.to AS tx_to
    ,dexs.trace_address
    ,dexs.evt_index
FROM dexs
INNER JOIN {{ source('avalanche_c', 'transactions')}} tx
    ON dexs.tx_hash = tx.hash
    {% if not is_incremental() %}
    AND tx.block_time >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND tx.block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ ref('tokens_erc20') }} erc20a
    ON erc20a.contract_address = dexs.token_bought_address
    AND erc20a.blockchain = 'avalanche_c'
LEFT JOIN {{ ref('tokens_erc20') }} erc20b
    ON erc20b.contract_address = dexs.token_sold_address
    AND erc20b.blockchain = 'avalanche_c'
LEFT JOIN {{ source('prices', 'usd') }} p_bought
    ON p_bought.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p_bought.contract_address = dexs.token_bought_address
    AND p_bought.blockchain = 'avalanche_c'
    {% if not is_incremental() %}
    AND p_bought.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND p_bought.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ source('prices', 'usd') }} p_sold
    ON p_sold.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p_sold.contract_address = dexs.token_sold_address
    AND p_sold.blockchain = 'avalanche_c'
    {% if not is_incremental() %}
    AND p_sold.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND p_sold.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ source('prices', 'usd') }} p_avx
    ON p_avx.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p_avx.blockchain is null
    AND p_avx.symbol = 'AVAX'
    {% if not is_incremental() %}
    AND p_avx.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND p_avx.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}