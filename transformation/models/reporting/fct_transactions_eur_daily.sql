{{ config(materialized='table', schema='reporting') }}

select
  customer_id,
  account_id,
  branch_id,
  transaction_date,
  sum(transaction_amount_eur)          as total_transaction_amount_eur,
  count(distinct transaction_id)       as total_transaction_count
from {{ ref('stg_raw_fact__transaction_all_summary') }} 
group by customer_id, account_id, branch_id, transaction_date 