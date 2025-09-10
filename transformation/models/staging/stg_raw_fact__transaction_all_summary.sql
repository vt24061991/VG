{{ config(materialized='table', schema='staging') }}

WITH curr AS (
  SELECT
    fx.currency_iso_code,
    fx.fx_rate_date,
    fx.fx_rate,
    c.currency AS currency_name
  FROM {{ ref('stg_raw_staging__fx_rates') }}           AS fx
  LEFT JOIN {{ ref('stg_raw_staging__currencies') }}    AS c
    ON fx.currency_iso_code = c.currency_iso_code
)

SELECT
  -- customer
  cus.customer_id, 
  cus.firstname,
  cus.lastname,
  cus.age,
  cus.branch_id,

  -- account
  acc.account_id,         
  acc.account_type,
  acc.account_opening_date,

  -- transaction 
  trans.transaction_id,
  trans.transaction_date,
  trans.currency_iso_code,
  trans.transaction_amount,
  
  -- new column with amount in EUR
  case
      when curr.currency_iso_code = 'EUR' then trans.transaction_amount
      else trans.transaction_amount / curr.fx_rate
    end as transaction_amount_eur,

  -- currency and rate
  curr.fx_rate_date,
  curr.fx_rate,
  curr.currency_name,

  -- loan 
  loan.loan_id,
  loan.loan_amount,
  loan.loan_type,
  loan.interest_rate,
  loan.loan_term,
  loan.approval_rejection_date,
  loan.loan_status

FROM {{ ref('stg_raw_staging__transactions') }} AS trans

LEFT JOIN {{ ref('stg_raw_staging__accounts') }}        AS acc  
ON acc.account_id   = trans.account_id

LEFT JOIN {{ ref('stg_raw_staging__customers_e1') }}    AS cus  
ON cus.customer_id  = acc.customer_id

LEFT JOIN curr                                                
ON curr.currency_iso_code = trans.currency_iso_code

LEFT JOIN {{ ref('stg_raw_staging__loans') }}           AS loan 
ON loan.customer_id = cus.customer_id
