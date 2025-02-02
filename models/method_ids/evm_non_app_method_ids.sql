
{{ config(
        schema = 'method_ids',
        alias ='evm_non_app_method_ids'
        )
}}


{% set all_chains_array = [
    'ethereum'
    ,'optimism'
    ,'arbitrum'
    ,'polygon'
    ,'gnosis'
    ,'avalanche_c'
    ,'fantom'
    ,'goerli'
    ,'bnb'
    ] %}

WITH aggrregate_methods AS (

SELECT NULL as blockchains, method_id, method_descriptor
    FROM UNNEST(ARRAY<STRUCT<method_id STRING,method_descriptor STRING>> [STRUCT('0x095ea7b3','ERC20 Approval') ,('0xa9059cbb','ERC20 Transfer') ,('0xd0e30db0','WETH Wrap') ,('0x2e1a7d4d','WETH Unwrap') ,('0x42842e0e','ERC721 Transfer'),
STRUCT('0x23b872dd','ERC721 Transfer') ,('0xb88d4fde','ERC721 Transfer'),
STRUCT('0xf3993d11','ERC721 Transfer'),
STRUCT('0xf242432a','ERC1155 Transfer'),
STRUCT('0x2eb2c2d6','ERC1155 Transfer'),
STRUCT('0xa22cb465','ERC721/ERC1155 Approval') ,('0x60806040','Contract Creation'),
STRUCT('0x60c06040','Contract Creation')])

UNION ALL 

SELECT 'optimism' AS blockchains, method_id, method_descriptor
    FROM UNNEST(ARRAY<STRUCT<method_id STRING,method_descriptor STRING>> [STRUCT('0xcbd4ece9','Bridge In (L1 to L2)') ,('0x32b7006d','Bridge Out (L2 to L1)') ,('0xbede39b5','OVM Gas Price Oracle'),
STRUCT('0xbf1fe420','OVM Gas Price Oracle') ,('0x015d8eb9','Set L1 Block Values')])

UNION ALL 

SELECT 'arbitrum' AS blockchains, method_id, method_descriptor
    FROM UNNEST(ARRAY<STRUCT<method_id STRING,method_descriptor STRING>> [STRUCT('0x6bf6a42d','ARBOS System Transaction') ,('0xc9f95d32', 'Submit Retryable Tx') ,('0x25e16063','Bridge Out (L2 to L1)') ,('0x7b3a3c8b','Bridge Out (L2 to L1)') ,('0x2e567b36','Bridge In (L1 to L2)')])

)


SELECT *
FROM (
    {% for chain in all_chains_array %}
    SELECT '{{chain}}' AS blockchain, method_id, method_descriptor
    FROM aggrregate_methods
    WHERE
        blockchains IS NULL 
        OR blockchains = '{{chain}}'
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)