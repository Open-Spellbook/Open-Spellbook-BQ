{{ config(
        alias='erc20_noncompliant',
        materialized = 'view',
        file_format = 'delta'
) 
}}

select distinct token_address
from {{ ref('transfers_ethereum_erc20_rolling_day') }}
where round(amount/power(10, 18), 6) < -0.001