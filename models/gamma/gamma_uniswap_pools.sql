 {{
  config(
        schema='gamma',
        alias='uniswap_pools',
        materialized = 'view',
                        unique_key = ['blockchain','contract_address', 'pool_contract']
  )
}}

{% set lp_models = [
  ref('gamma_optimism_uniswap_pools')
] %}


SELECT *
FROM (
    {% for g_lp_lm_model in lp_models %}
    SELECT
      blockchain
    , 'gamma' AS project
    , lp_name
    , contract_address
    , pool_contract
    , fee
    , token0
    , token1
        
    FROM {{ g_lp_lm_model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)