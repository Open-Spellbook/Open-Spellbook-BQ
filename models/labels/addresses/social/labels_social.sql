{{ config(
    alias = 'social',
    materialized = 'view')
}}

{% set social_models = [
  ref('labels_ens')
, ref('labels_three_letter_ens_count')
 ,ref('labels_lens_poster_frequencies')
] %}

SELECT *
FROM (
    {% for social_model in social_models %}
    SELECT
        blockchain,
        address,
        name,
        case when category = 'ENS' then 'social' else category end as category,
        contributor,
        source,
        created_at,
        updated_at,
        model_name,
        label_type
    FROM {{ social_model }}
    {% if not loop.last %}
    UNION ALL
    {% endif %}
    {% endfor %}
)