{{ config(
    alias = 'trades',
    partition_by = {"field": "block_date"},
    materialized = 'view',
            unique_key = ['block_date', 'blockchain', 'project', 'version', 'tx_hash', 'evt_index', 'trace_address']
    )
}}

{% set project_start_date = '2022-05-10' %}

with iziswap_swaps as (
	select
		contract_address
		, evt_tx_hash
		, evt_index
		, evt_block_time
		, case when sellXEarnY then tokenY else tokenX end as token_bought_address 
		, case when sellXEarnY then tokenX else tokenY end as token_sold_address
		, case when sellXEarnY then amountY else amountX end as token_bought_amount_raw 
		, case when sellXEarnY then amountX else amountY end as token_sold_amount_raw
	from 
		{{ source('izumi_bnb', 'iZiSwapPool_evt_Swap') }}
	{% if is_incremental() %}
    where evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
)
select
	'bnb' as blockchain
	, 'iziswap' as project
	, '1' as version
	, TIMESTAMP_TRUNC(s.evt_block_time, DAY) as block_date
	, s.evt_block_time as block_time
    , CAST(s.token_bought_amount_raw  AS BIGNUMERIC) AS token_bought_amount_raw
    , CAST(s.token_sold_amount_raw AS BIGNUMERIC) AS token_sold_amount_raw
    , coalesce(
        (s.token_bought_amount_raw / power(10, prices_b.decimals)) * prices_b.price
        ,(s.token_sold_amount_raw / power(10, prices_s.decimals)) * prices_s.price
    ) as amount_usd	
	, s.token_bought_address as token_bought_address
	, s.token_sold_address as token_sold_address
	, erc20_b.symbol as token_bought_symbol
	, erc20_s.symbol as token_sold_symbol
	, case
        when lower(erc20_b.symbol) > lower(erc20_s.symbol) then concat(erc20_s.symbol, '-', erc20_b.symbol)
        else concat(erc20_b.symbol, '-', erc20_s.symbol)
    end as token_pair
	, s.token_bought_amount_raw / power(10, erc20_b.decimals) as token_bought_amount
	, s.token_sold_amount_raw / power(10, erc20_s.decimals) as token_sold_amount
    , tx.from as taker
	, '' as maker
	, cast(s.contract_address as string) as project_contract_address
	, s.evt_tx_hash as tx_hash
    , tx.from as tx_from
    , tx.to as tx_to
	, '' as trace_address
	, s.evt_index as evt_index
from 
    iziswap_swaps s
inner join {{ source('bnb', 'transactions') }} tx
    on tx.hash = s.evt_tx_hash
    {% if not is_incremental() %}
    and tx.block_time >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    and tx.block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
-- bought tokens
left join {{ ref('tokens_erc20') }} erc20_b
    on erc20_b.contract_address = s.token_bought_address 
    and erc20_b.blockchain = 'bnb'
-- sold tokens
left join {{ ref('tokens_erc20') }} erc20_s
    on erc20_s.contract_address = s.token_sold_address
    and erc20_s.blockchain = 'bnb'
-- price of bought tokens
left join {{ source('prices', 'usd') }} prices_b
    on prices_b.minute = TIMESTAMP_TRUNC(s.evt_block_time, minute)
    and prices_b.contract_address = s.token_bought_address
    and prices_b.blockchain = 'bnb'
	{% if not is_incremental() %}
    and prices_b.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    and prices_b.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}
-- price of sold tokens
left join {{ source('prices', 'usd') }} prices_s
    on prices_s.minute = TIMESTAMP_TRUNC(s.evt_block_time, minute)
    and prices_s.contract_address = s.token_sold_address
    and prices_s.blockchain = 'bnb'
	{% if not is_incremental() %}
    and prices_s.minute >= '{{project_start_date}}'
    {% endif %}
    {% if is_incremental() %}
    and prices_s.minute >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
    {% endif %}