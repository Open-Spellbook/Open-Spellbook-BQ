{{ config(
    schema = 'tigris_v2_polygon',
    alias = 'events_close_position',
    partition_by = {"field": "day"},
    materialized = 'view',
            unique_key = ['evt_block_time', 'evt_tx_hash', 'position_id', 'trader', 'price', 'payout', 'perc_closed']
    )
}}

WITH 

close_position_v1 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            id as position_id,
            closePrice/1e18 as price, 
            payout/1e18 as payout, 
            percent/1e8 as perc_closed, 
            trader 
        FROM 
        {{ source('tigristrade_v2_polygon', 'Trading_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
),

close_position_v2 as (
        SELECT 
            TIMESTAMP_TRUNC(evt_block_time, day) AS `day`, 
            evt_tx_hash,
            evt_index,
            evt_block_time,
            id as position_id,
            closePrice/1e18 as price, 
            payout/1e18 as payout, 
            percent/1e8 as perc_closed, 
            trader 
        FROM 
        {{ source('tigristrade_v2_polygon', 'TradingV2_evt_PositionClosed') }}
        {% if is_incremental() %}
        WHERE evt_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
)

SELECT *, '2.1' as version FROM close_position_v1

UNION ALL 

SELECT *, '2.2' as version FROM close_position_v2