{{
    config(
        alias='dex_traders'
    )
}}

with 
 dex_traders as (
 SELECT address, blockchain
 FROM (
    select taker as address, blockchain
    from {{ref('dex_trades')}}
    GROUP BY taker, blockchain  --distinct
    UNION ALL
    select tx_from as address, blockchain
    from {{ref('dex_trades')}}
     GROUP BY tx_from, blockchain --distinct
     ) uni
  GROUP BY address, blockchain--distinct
  )
select
  blockchain,
  address,
  "DEX Trader" AS name,
  "dex" AS category,
  "gentrexha" AS contributor,
  "query" AS source,
  timestamp('2022-12-14') as created_at,
  CURRENT_TIMESTAMP() as updated_at,
  "dex_traders" as model_name,
  "persona" as label_type
from
  dex_traders