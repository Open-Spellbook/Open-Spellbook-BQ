{{ config(
        alias ='pools'
        )
}}

{% set uniswap_models = [
ref('uniswap_ethereum_pools')
] %}


SELECT *
FROM (
    {% for dex_pool_model in uniswap_models %}
    SELECT
        blockchain
        , project
        , version
        , pool
        , fee
        , token0
        , token1
        , creation_block_time
        , creation_block_number
        , contract_address
    FROM {{ dex_pool_model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)