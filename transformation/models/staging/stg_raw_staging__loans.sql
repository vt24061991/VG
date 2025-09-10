with source as (

    select * from {{ source('raw', 'loans') }}

),

renamed as (

    select
        customer_id,
        loan_id,
        {{ parse_decimal("loan_amount", 18, 5) }} as loan_amount,
        loant_type as loan_type,
        {{ parse_decimal("interest_rate", 18, 5) }} as interest_rate,
        loan_term,
        case
          when lower(trim(approval_rejection_date)) in ('', 'na', 'n/a', 'null') then null
          else coalesce(
            try_strptime(trim(approval_rejection_date), '%d.%m.%Y'),
            try_strptime(trim(approval_rejection_date), '%Y-%m-%d'),
            try_strptime(trim(approval_rejection_date), '%d/%m/%Y')
          )::date
        end as approval_rejection_date,
        
        loan_status

    from source

)

select * from renamed