{{ config(
    alias = 'itokens'
) }}

SELECT
    symbol, 
    contract_address, 
    decimals, 
    underlying_token_address, 
    underlying_decimals, 
    underlying_symbol
FROM UNNEST(ARRAY<STRUCT<symbol STRING,contract_address STRING,decimals INT64,underlying_token_address STRING,underlying_decimals INT64,underlying_symbol STRING>> [STRUCT('iWETH', '0x17533a1bde957979e3977ebbfbc31e6deeb25c7d', 8, '0x4200000000000000000000000000000000000006', 18, 'WETH'),
STRUCT('iUSDC', '0x1d073cf59ae0c169cbc58b6fdd518822ae89173a', 8, '0x7f5c764cbc14f9669b88837ca1490cca17c31607', 6, 'USDC'),
STRUCT('iUSDT', '0x874c01c2d1767efa01fa54b2ac16be96fad5a742', 8, '0x94b008aa00579c1307b0ef2c499ad98a8ce58e58', 6, 'USDT'),
STRUCT('iDAI', '0x049e04bee77cffb055f733a138a2f204d3750283', 8, '0xda10009cbd5d07dd0cecc66161fc93d7c9000da1', 18, 'DAI'),
STRUCT('iWBTC', '0xcdb9b4db65c913ab000b40204248c8a53185d14d', 8, '0x68f180fcce6836688e9084f035309e29bf0a2095', 8, 'WBTC'),
STRUCT('iOP', '0x4645e0952678e9566fb529d9313f5730e4e1c412', 8, '0x4200000000000000000000000000000000000042', 18, 'OP'),
STRUCT('iSNX', '0xe724ffa5d30782499086682c8362cb3673bf69ae', 8, '0x8700daec35af8ff88c16bdf0418774cb3d7599b4', 18, 'SNX'),
STRUCT('iSUSD', '0x04f0fd3cd03b17a3e5921c0170ca6dd3952841ca', 8, '0x8c6f28f2f1a3c87f0f938b96d27520d9751ec8d9', 18, 'sUSD')])