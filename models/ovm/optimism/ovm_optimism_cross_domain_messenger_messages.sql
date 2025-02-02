{{ config(
    alias = 'cross_domain_messenger_messages',
    partition_by = {"field": "l2_block_date"},
    materialized = 'view',
            unique_key = ['msg_type','l2_block_date', 'l2_tx_hash', 'evt_index','msg_index']
    )
}}

SELECT 'withdraw' AS msg_type, 'SentMessage' AS event, sender,
    evt_tx_hash AS l2_tx_hash, evt_block_number AS l2_block_number, 
    evt_block_time AS l2_block_time, TIMESTAMP_TRUNC(evt_block_time, day) AS l2_block_date,
    contract_address, target, messageNonce AS message_nonce_hash, evt_index, '2' AS version,
    DENSE_RANK() OVER (PARTITION BY evt_tx_hash ORDER BY evt_index ASC) AS msg_index
    
    FROM {{ source ('ovm_optimism', 'L2CrossDomainMessenger_evt_SentMessage') }}
    {% if is_incremental() %}
    WHERE evt_block_time >= (CURRENT_TIMESTAMP() - interval '14 days')
    {% endif %}

    
UNION ALL

SELECT 'deposit' AS m_type, 'RelayedMessage' AS event, '' as sender,
    evt_tx_hash AS l2_tx_hash, evt_block_number AS l2_block_number, 
    evt_block_time AS l2_block_time, TIMESTAMP_TRUNC(evt_block_time, day) AS l2_block_date,
    contract_address, NULL AS target, msgHash AS message_nonce_hash, evt_index, '2' AS version,
    DENSE_RANK() OVER (PARTITION BY evt_tx_hash ORDER BY evt_index ASC) AS msg_index

    FROM {{ source ('ovm_optimism', 'L2CrossDomainMessenger_evt_RelayedMessage') }}
    {% if is_incremental() %}
    WHERE evt_block_time >= (CURRENT_TIMESTAMP() - interval '14 days')
    {% endif %}