with source as (

    select * from {{ source('raw', 'accounts') }}

),

renamed as (

    select
        account_id,
        customer_id,
        account_type,
        --strptime(account_opening_date, '%d.%m.%Y') as account_opening_date
        case
          when lower(trim(account_opening_date)) in ('', 'na', 'n/a', 'null') then null
          else coalesce(
            try_strptime(trim(account_opening_date), '%d.%m.%Y'),
            try_strptime(trim(account_opening_date), '%Y-%m-%d'),
            try_strptime(trim(account_opening_date), '%d/%m/%Y')
          )::date
        end as account_opening_date,
    from source

)

select * from renamed