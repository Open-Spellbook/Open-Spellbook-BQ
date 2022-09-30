{{ config(
	alias ='trades',
	partition_by = ['block_date'],
	materialized = 'incremental',
	file_format = 'delta',
	incremental_strategy = 'merge',
	unique_key = ['block_time', 'project', 'version', 'tx_hash', 'evt_index'],
    post_hook='{{ expose_spells(\'["optimism"]\',
                                "project",
                                "synthetix",
                                \'["MSilb7", "drethereum", "rplust"]\') }}'
	)
}}

{% set project_start_date = '2021-11-22' %}

WITH asset_price AS (
	SELECT
		s.contract_address AS market_address
		,DECODE(
			UNHEX(
				SUBSTRING(sm.asset, 3)
				), 'UTF-8'
			) AS asset
		,s.evt_block_time
		,AVG(s.lastPrice/1e18) AS price
	FROM {{ source('synthetix_optimism', 'FuturesMarket_evt_PositionModified') }} AS s
	LEFT JOIN {{ source('synthetix_optimism', 'FuturesMarketManager_evt_MarketAdded') }} AS sm
		ON s.contract_address = sm.market
	{% if is_incremental() %}
	WHERE s.evt_block_time >= DATE_TRUNC("DAY", NOW() - INTERVAL '1 WEEK')
	{% endif %}
	GROUP BY market_address, asset, s.evt_block_time
),

perps AS (
	SELECT
		s.evt_block_time AS block_time
		,DECODE(
			UNHEX(
				SUBSTRING(sm.asset, 3)
				), 'UTF-8'
			) AS virtual_asset
		--gets the last element in an array that is formed by splitting the asset name from the synthetic indicator, 's'
		,ELEMENT_AT(
			SPLIT(
				DECODE(
					UNHEX(
						SUBSTRING(sm.asset, 3)
						), 'UTF-8'
					), '[s]'
				),
			--the asset will always be the last element of the array split (including none synthetic assets) so we need the array size
				ARRAY_SIZE(
					SPLIT(
						DECODE(
							UNHEX(
								SUBSTRING(sm.asset, 3)
								), 'UTF-8'
							), '[s]'
						))) AS underlying_asset
		,DECODE(
			UNHEX(
				SUBSTRING(sm.marketKey, 3)
				), 'UTF-8'
			) AS market
		,s.contract_address AS market_address
		,ABS(s.tradeSize) * p.price AS volume_usd
		,s.fee/1e18 AS fee_usd
		,s.margin/1e18 AS margin_usd
		,(ABS(s.tradeSize)/1e18 * p.price) / (s.margin/1e18) AS leverage_ratio

		,CASE
		WHEN (CAST(s.margin AS DOUBLE) >= 0 AND CAST(s.size AS DOUBLE) = 0 AND CAST(s.tradeSize AS DOUBLE) < 0 AND s.size != s.tradeSize) THEN 'close'
		WHEN (CAST(s.margin AS DOUBLE) >= 0 AND CAST(s.size AS DOUBLE) = 0 AND CAST(s.tradeSize AS DOUBLE) > 0 AND s.size != s.tradeSize) THEN 'close'
		WHEN CAST(s.tradeSize AS DOUBLE) > 0 THEN 'long'
		WHEN CAST(s.tradeSize AS DOUBLE) < 0 THEN 'short'
		ELSE 'NA'
		END AS trade

		,'Synthetix' AS project
		,'1' AS version
		,s.account AS trader
		,s.tradeSize AS volume_raw
		,s.evt_tx_hash AS tx_hash
		,s.evt_index
	FROM {{ source('synthetix_optimism', 'FuturesMarket_evt_PositionModified') }} AS s
	LEFT JOIN {{ source('synthetix_optimism', 'FuturesMarketManager_evt_MarketAdded') }} AS sm
		ON s.contract_address = sm.market
	LEFT JOIN asset_price AS p
		ON s.contract_address = p.market_address
		AND s.evt_block_time = p.evt_block_time
	WHERE s.tradeSize != 0
	{% if is_incremental() %}
	AND s.evt_block_time >= DATE_TRUNC("DAY", NOW() - INTERVAL '1 WEEK')
	{% endif %}
)

SELECT
	'optimism' AS blockchain
    ,TRY_CAST(date_trunc('DAY', perps.block_time) AS date) AS block_date
	,perps.block_time
	,perps.virtual_asset
	,perps.underlying_asset
	,perps.market
	,perps.market_address
	,perps.volume_usd
	,perps.fee_usd
	,perps.margin_usd
	,perps.trade
	,perps.project
	,perps.version
	,perps.trader
	,perps.volume_raw
	,perps.tx_hash
	,tx.from AS tx_from
	,tx.to AS tx_to
	,perps.evt_index
FROM perps
INNER JOIN {{ source('optimism', 'transactions') }} AS tx
	ON perps.tx_hash = tx.hash
	{% if not is_incremental() %}
	AND tx.block_time >= '{{project_start_date}}'
	{% endif %}
	{% if is_incremental() %}
	AND tx.block_time >= DATE_TRUNC("DAY", NOW() - INTERVAL '1 WEEK')
	{% endif %}