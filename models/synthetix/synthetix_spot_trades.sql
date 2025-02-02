{{ config(
        alias ='spot_trades'
        )
}}

{% set snx_models = [
ref('synthetix_optimism_spot_trades')
] %}


SELECT *
FROM (
    {% for snx_model in snx_models %}
    SELECT
        blockchain,
        project,
        version,
        block_date,
        block_time,
        token_bought_symbol,
        token_sold_symbol,
        token_pair,
        token_bought_amount,
        token_sold_amount,
        CAST(token_bought_amount_raw AS BIGNUMERIC) AS token_bought_amount_raw,
        CAST(token_sold_amount_raw AS BIGNUMERIC) AS token_sold_amount_raw,
        amount_usd,
        token_bought_address,
        token_sold_address,
        taker,
        maker,
        project_contract_address,
        tx_hash,
        tx_from,
        tx_to,
        trace_address,
        evt_index
    FROM {{ snx_model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)