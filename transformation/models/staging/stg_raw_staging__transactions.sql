with source as (

    select * from {{ source('raw', 'transactions') }}

),

renamed as (

    select
        transaction_id,
        coalesce(
            try_strptime(nullif(trim(transaction_date), ''), '%d.%m.%Y'),
            try_strptime(transaction_date, '%Y-%m-%d')
        )::date as transaction_date,
        account_id, 
        transaction_type,
        {{ parse_decimal("transaction_amount", 18, 5) }} as transaction_amount, 
        left(trim(transaction_currency), 3) as currency_iso_code

    from source

)

select * from renamed