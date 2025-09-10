
with source as (

    select * from {{ source('raw', 'fx_rates') }}

),

renamed as (

    select
        trim(currency_iso_code) as currency_iso_code,
        {{ parse_decimal("fx_rate", 18, 5) }} as fx_rate,
        strptime(date, '%d.%m.%Y') as fx_rate_date

    from source
    where currency_iso_code is not null or currency_iso_code != '' 

)

select * from renamed