{{ config(alias='addresses_1', materialized = 'view', file_format = 'delta') }}

SELECT address, a_is_voter,b_is_multisig_signer,c_is_gitcoin,d_is_price_out,e_op_user,f_op_repeat,num_categories_if_op_user,g_overlap_bonus,total_op_eligible_to_claim
FROM
  {{ ref( 'airdrop_optimism_addresses_1_0_seed' ) }}