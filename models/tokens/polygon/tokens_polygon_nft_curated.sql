{{ config(alias='nft_curated', tags=['static']) }}

SELECT
  LOWER(contract_address) AS contract_address, name, '' as symbol
FROM UNNEST(ARRAY<STRUCT<contract_address STRING,name STRING>> [STRUCT('0xdb46d1dc155634fbc732f92e853b10b288ad5a1d',	'Lens Protocol Profiles'),
STRUCT('0x9d305a42a3975ee4c1c57555bed5919889dce63f',	'Sandboxs LANDs')])