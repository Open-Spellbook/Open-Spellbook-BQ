{{config(alias='cex_bitcoin')}}

SELECT blockchain, lower(address) as address, name, category, contributor, source, created_at, updated_at, model_name, label_type
FROM UNNEST(ARRAY<STRUCT<blockchain STRING,address STRING,name STRING,category STRING,contributor STRING,source STRING,created_at TIMESTAMP,updated_at TIMESTAMP,model_name STRING,label_type STRING>> [STRUCT('bitcoin','34xp4vRoCGJym3xR7yCVPFHoCNxv4Twseo', 'Binance 1', 'institution', 'ilemi', 'static', timestamp('2023-03-28'), CURRENT_TIMESTAMP(), 'cex_bitcoin', 'identifier'),
STRUCT('bitcoin', '38ztxG7GL1LEEbC9gKpqEKEh7WZ3KDTLMi', 'Binance 2', 'institution', 'ilemi', 'static', timestamp('2023-03-28'), CURRENT_TIMESTAMP(), 'cex_bitcoin', 'identifier'),
STRUCT('bitcoin', '399QCnqVzAt4HGU1SV7PfVPYovb1BX3u9Y', 'Binance 3', 'institution', 'ilemi', 'static', timestamp('2023-03-28'), CURRENT_TIMESTAMP(), 'cex_bitcoin', 'identifier'),
STRUCT('bitcoin', '3HdGoUTbcztBnS7UzY4vSPYhwr424CiWAA', 'Binance 4', 'institution', 'ilemi', 'static', timestamp('2023-03-28'), CURRENT_TIMESTAMP(), 'cex_bitcoin', 'identifier')])