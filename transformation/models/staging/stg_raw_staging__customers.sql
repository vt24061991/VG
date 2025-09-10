with source as (

    select * from {{ source('raw', 'customers') }}

),

renamed as (

    select
        customer_id, 
        firstname,
        lastname,
        Age as 'age', 
        branch_id

    from source

)

select * from renamed