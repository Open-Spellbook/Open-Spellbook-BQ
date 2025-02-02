{{ config(
        alias ='nft'
        , materialized = 'view'
        
        )
}}

SELECT
    c.contract_address
  , coalesce(t.name,b.name) as name
  , coalesce(t.symbol,b.symbol) as symbol
  , c.standard
FROM {{ ref('tokens_optimism_nft_standards')}} c
LEFT JOIN  {{ref('tokens_optimism_nft_curated')}} t
    ON c.contract_address = t.contract_address
LEFT JOIN {{ ref('tokens_optimism_nft_bridged_mapping')}} b
    ON c.contract_address = b.contract_address