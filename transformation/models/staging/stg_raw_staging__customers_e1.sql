with source as (
  select * from {{ ref('stg_raw_staging__customers') }}
),
dedup as (
  select
    *,
    row_number() over (partition by customer_id order by customer_id) as rn
  from source
)

-- keep one row per customer_id
select * exclude (rn)
from dedup
where rn = 1