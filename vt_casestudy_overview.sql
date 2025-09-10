-- VT: Casestudy Overview

-- 0) Check the table currencies which need to be imported
/* this table is to be imported as seed with dbt. The file is located at data/currencies.csv.
I used a file call import_seed.py to change the delimiter from ; to ,  so that i can import it as seed.
There're 171 rows in total but only 169 rows are inserted in database. Duplicated rows have been removed (USDollar and USD) 
seed is in main, imported as raw data. There're a staging table for currencies latter as well. This is not related to the task. 
But i included it in the staging fact table in case it's useful for future analysis.
*/
---------------------------------
-- 1) Customers
---------------------------------
-- 1.1) run test for all raw tables, it turns out that only customers table has issue
-- Staging Customers fail the uniqueness test. Therefore, i checked the raw table
select customer_id, COUNT(*) as cnt from raw.customers GROUP BY customer_id HAVING cnt > 1 ORDER BY cnt DESC LIMIT 10; 
--- duplicate found for customer_id = 1

-- 1.2) check the duplicate records for customer_id = 1
select * from raw.customers where customer_id = '1';
/*
Joshua	Heck 
Joshua	Heck
*/
---------------------------------
-- 2) fx_rates : only 15 distinct currency_iso_code
---------------------------------

select * from raw.fx_rates;  --> 4 column but one column is null and is not used (column 4)
-- 15 rows
select count(*) from raw.fx_rates;
-- 15 rows
select count(DISTINCT(currency_iso_code)) from raw.fx_rates;

---------------------------------
-- 3) Accounts: account_id is identical to customer_id
---------------------------------
-- pass the uniqueness test --> no duplicate
-- 5000 rows
select COUNT(*) from raw.accounts;
-- 5000 distinct rows   
select COUNT(DISTINCT(account_id)) from raw.accounts; 

-- 0 row --> account_id is identical to customer_id. This is a coincidence? anyways, it helps me do the task latter a bit easier
select * from raw.accounts where customer_id != account_id; 


----------------------------------
-- 4) Loan: not related to the task, has messy data types, which need to be fixed in staging layer
----------------------------------
-- pass the uniqueness test --> no duplicate
select * from raw.loans;
--> Data format is messy, e.g approval_rejection_date is varchar instead of date, amount is varchar instead of decimal, rate is varchar instead of decimal
--> need to be change in staging layer

select distinct loan_status from raw.loans; 
/*
approved
closed
rejected
*/

select distinct loant_type from raw.loans;
/*
auto
personal
mortgage
*/

----------------------------------
-- 5) Transactions: has messy data types, which need to be fixed in staging layer
----------------------------------
select * from raw.transactions;
--> Data format is messy, e.g transaction_date is varchar instead of date, transaction_amount is varchar instead of decimal
--> need to be change in staging layer
-- currecny_iso_code does not pass the currency code test 
-- RON1 (Romanian leu)--> to be fixed in staging layer and use as a test case later
select * from raw.transactions where length(trim(transaction_currency)) != 3;

----------------------------------
-- 6) Analyis after building the fact tables: 
-- Staging fact table are staging for e.g a historical fact table. Therefore, it contains personal data as well (e.g firstname, lastname, age).
-- It's for the checking data quality only and in case question from requestors came. There are no personal data in the reporting fact table or the out-view for reporting.
----------------------------------
-- 6.1) check the staging fact table
-- check if there is any customer with more than same transactionid 
-- 0 row
SELECT
  customer_id,
  transaction_id,
  COUNT(*) AS dup_rows
FROM staging.stg_raw_fact__transaction_all_summary
WHERE transaction_id IS NOT NULL
GROUP BY customer_id, transaction_id
HAVING COUNT(*) >1
ORDER BY dup_rows DESC, customer_id, transaction_id;

---> they can be set as primary key(unique) for a historical fact table, which is out of scope for this task.
--------------------------------
-- check if there is any null transaction amount (in case RON1 is not fixed in staging layer)
-- 0 row --> ok
select *
from staging.stg_raw_fact__transaction_all_summary
where transaction_amount_eur is null
limit 10;
--------------------------------
--- 6.2) Comparison between staging and reporting fact table
-- check staging fact table for 1 customer
WITH t AS 
 (
--- 16 transactions
  SELECT
    transaction_id,
    SUM(transaction_amount_eur) AS total_transaction_amount_eur
  FROM staging.stg_raw_fact__transaction_all_summary
  WHERE customer_id = 645
  GROUP BY transaction_id

) 
--- 11909.72
SELECT ROUND(SUM(total_transaction_amount_eur), 2) AS grand_total_eur
FROM t
;
--cross check with fact table in reporting
-- 11909.72 --> ok
select ROUND(SUM(total_transaction_amount_eur), 2) AS grand_total_eur from reporting.fct_transactions_eur_daily where customer_id = 645 ;
-- 11909.72 --> ok
select ROUND(SUM(total_transaction_amount_eur), 2) AS grand_total_eur from reporting.out_fct_transaction_eur_daily where customer_id = 645 ;

-- check details for customer 645 on 2025-02-04 ( highest transaction date for this customer) 
with t as (
    -- 4 transactions on this date
    select * from (
        SELECT
            transaction_id,
            transaction_date,
            SUM(transaction_amount_eur) AS total_transaction_amount_eur
        FROM staging.stg_raw_fact__transaction_all_summary
        WHERE customer_id = 645
        GROUP BY transaction_id, transaction_date
    ) sub
    WHERE transaction_date = '2025-02-04'
)
--- 5218.04
SELECT SUM(total_transaction_amount_eur) AS grand_total_eur from t
    ;

-- cross check with fact table in reporting
-- 5218.04 --> ok
select * from reporting.fct_transactions_eur_daily where customer_id = 645 and transaction_date = '2025-02-04';
-- 5218.04 --> ok
select * from reporting.out_fct_transaction_eur_daily where customer_id = 645 and transaction_date = '2025-02-04';
----------------------------------
-- end

