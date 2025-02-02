{{ config(
    alias = 'reverse_latest',
    materialized = 'view',
            unique_key = ['address']
    )
}}

--latest Node <> Name relations
with node_names as (
    select
    name,node,block_time,tx_hash
    from (
        select
        case when _name = '0x0000000000000000000000000000000000000000' then null else _name end as name
        ,node
        ,call_block_time as block_time
        ,call_tx_hash as tx_hash
        ,row_number() over (partition by node order by call_block_time desc) as ordering --in theory we should also order by tx_index here
        from {{ source('ethereumnameservice_ethereum', 'DefaultReverseResolver_call_setName') }}
        where call_success
        {% if is_incremental() %}
        AND call_block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}
    ) foo
    where ordering = 1
)

--static Node <> Address relations
, address_nodes as (select distinct
    tr.from as address,
    output as node
    from {{ source('ethereum', 'traces') }} tr
    where success
        and (to = '0x9062c0a6dbd6108336bcbe4593a3d1ce05512069' -- ReverseRegistrar v1
            or  `to` = '0x084b1c3c81545d370f3634392de611caabff8148' -- ReverseRegistrar v2
        )
        and substring(input,1,10) in (
            '0xc47f0027' -- setName(string)
            ,'0x0f5a5466' -- claimWithResolver(address,address)
            ,'0x1e83409a' -- claim(address)
            )
        {% if is_incremental() %}
        AND block_time >= date_trunc("day", CURRENT_TIMESTAMP() - interval '1 week')
        {% endif %}

)

select
    address
    ,name
    ,block_time as latest_tx_block_time
    ,tx_hash as latest_tx_hash
    ,an.node as address_node
from address_nodes an
left join node_names nn
ON an.node = nn.node