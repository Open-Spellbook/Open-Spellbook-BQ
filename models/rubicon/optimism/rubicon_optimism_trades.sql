{{ config(
    schema = 'rubicon_optimism',
    alias = 'trades',
    partition_by = {"field": "block_date"},
    materialized = 'view',
            unique_key = ['block_date', 'blockchain', 'project', 'version', 'tx_hash', 'evt_index', 'trace_address']
    )
}}
-- First swap event 2022-05-23
{% set project_start_date = '2022-05-23' %}

WITH dexs AS
(
    -- -- useful syntax when dealing with the event LogTake
    -- -- pay_gem corresponds with take_amt - this is what the taker is taking and what the maker is selling
    -- -- buy_gem corresponds with give_amt - this is what the taker is giving and what the maker is buying

    --From the prespective of the taker
    SELECT
         t.evt_block_time AS block_time
        , t.evt_block_number
        ,t.taker AS taker
        ,t.maker AS maker
        ,t.take_amt AS token_bought_amount_raw
        ,t.give_amt AS token_sold_amount_raw
        ,cast(NULL as FLOAT64) AS amount_usd
        ,t.pay_gem AS token_bought_address
        ,t.buy_gem AS token_sold_address
        ,t.contract_address as project_contract_address
        ,t.evt_tx_hash AS tx_hash
        ,'' AS trace_address
        ,t.evt_index
    FROM
        {{ source('rubicon_optimism', 'RubiconMarket_evt_LogTake') }} t
        
    WHERE t.evt_block_time >= '{{project_start_date}}'
    {% if is_incremental() %}
    AND t.evt_block_time >= date_trunc('day', CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
)
SELECT
     'optimism' AS blockchain
    ,'rubicon' AS project
    ,'1' AS version
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
        ,(dexs.token_bought_amount_raw / power(10, p_bought.decimals)) * p_bought.price
        ,(dexs.token_sold_amount_raw / power(10, p_sold.decimals)) * p_sold.price
    ) AS amount_usd
    ,dexs.token_bought_address
    ,dexs.token_sold_address
    ,dexs.taker
    ,dexs.maker
    ,dexs.project_contract_address
    ,dexs.tx_hash
    ,tx.from AS tx_from
    ,tx.to AS tx_to
    ,dexs.trace_address
    ,dexs.evt_index
FROM dexs
INNER JOIN {{ source('optimism', 'transactions') }} tx
    ON tx.hash = dexs.tx_hash
    AND tx.block_number = dexs.evt_block_number
    {% if not is_incremental() %}
    AND tx.block_time >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND tx.block_time >= date_trunc('day', CURRENT_TIMESTAMP() - interval '1' week)
    {% endif %}
LEFT JOIN {{ ref('tokens_erc20') }} erc20a
    ON erc20a.contract_address = dexs.token_bought_address 
    AND erc20a.blockchain = 'optimism'
LEFT JOIN {{ ref('tokens_erc20') }} erc20b
    ON erc20b.contract_address = dexs.token_sold_address
    AND erc20b.blockchain = 'optimism'
LEFT JOIN {{ source('prices', 'usd') }} p_bought
    ON p_bought.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p_bought.contract_address = dexs.token_bought_address
    AND p_bought.blockchain = 'optimism'
    {% if not is_incremental() %}
    AND p_bought.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND p_bought.minute >= date_trunc('day', CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
LEFT JOIN {{ source('prices', 'usd') }} p_sold
    ON p_sold.minute = TIMESTAMP_TRUNC(dexs.block_time, minute)
    AND p_sold.contract_address = dexs.token_sold_address
    AND p_sold.blockchain = 'optimism'
    {% if not is_incremental() %}
    AND p_sold.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    AND p_sold.minute >= date_trunc('day', CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}