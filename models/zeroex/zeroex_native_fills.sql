{{ config(
        alias ='native_fills'
        )
}}

{% set zeroex_models = [  
ref('zeroex_ethereum_native_fills')
,ref('zeroex_polygon_native_fills')
,ref('zeroex_optimism_native_fills')
,ref('zeroex_arbitrum_native_fills')
,ref('zeroex_bnb_native_fills')
] %}


SELECT *
FROM (
    {% for model in zeroex_models %}
    SELECT
    *
    FROM {{ model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)