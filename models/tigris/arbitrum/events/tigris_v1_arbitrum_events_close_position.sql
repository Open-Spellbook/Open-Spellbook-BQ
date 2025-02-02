{{ config(
    schema = 'tigris_v1_arbitrum',
    alias = 'events_close_position',
    partition_by = {"field": "day"},
    materialized = 'view',
            unique_key = ['evt_block_time', 'evt_tx_hash', 'position_id', 'trader', 'price', 'payout', 'perc_closed']
    )
}}

WITH 

close_position_v2 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            _id as position_id,
            _closePrice/1e18 as price, 
            _payout/1e18 as payout, 
            _percent/1e8 as perc_closed, 
            _trader as trader 
        FROM 
        {{ source('tigristrade_arbitrum', 'TradingV2_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
),

close_position_v3 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            _id as position_id,
            _closePrice/1e18 as price, 
            _payout/1e18 as payout, 
            _percent/1e8 as perc_closed, 
            _trader as trader 
        FROM 
        {{ source('tigristrade_arbitrum', 'TradingV3_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
),

close_position_v4 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            _id as position_id,
            _closePrice/1e18 as price, 
            _payout/1e18 as payout, 
            _percent/1e8 as perc_closed, 
            _trader as trader 
        FROM 
        {{ source('tigristrade_arbitrum', 'TradingV4_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
),

close_position_v5 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            _id as position_id,
            _closePrice/1e18 as price, 
            _payout/1e18 as payout, 
            _percent/1e8 as perc_closed, 
            _trader as trader 
        FROM 
        {{ source('tigristrade_arbitrum', 'TradingV5_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
)


SELECT *, '1.2' as version FROM close_position_v2

UNION ALL

SELECT *, '1.3' as version FROM close_position_v3

UNION ALL

SELECT *, '1.4' as version FROM close_position_v4

UNION ALL

SELECT *, '1.5' as version FROM close_position_v5