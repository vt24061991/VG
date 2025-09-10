{#
  Staging currencies model
  - Map '(none)'/blanks to NULL
  - Uppercase and take first 3 letters for codes; invalidate non A–Z
  - Deduplicate by (code, currency) so NULL-code currencies are kept individually
  - After that, take only rows with non-null codes 
  - Align date type with other staging models
#}

with cleaned as (
    select
        /* normalize currency text */
        case
          when lower(trim(currency)) in ('', '(none)', 'none', 'null') then null
          else trim(currency)
        end as currency,

        /* normalize code: NULL if '(none)'/blank/non-alpha; else first 3 letters uppercased */
        case
          when lower(trim(currency_iso_code)) in ('', '(none)', 'none', 'null') then null
          when upper(trim(currency_iso_code)) ~ '^[A-Z]{3}' then left(upper(trim(currency_iso_code)), 3)
          else null
        end as currency_iso_code
    from {{ ref('currencies') }}
),

ranked as (
    select
        *,
        row_number() over (
          partition by
            /* keep one per (code, currency); preserves all NULL-code currencies */
            currency_iso_code,
            upper(currency)
          order by currency nulls last
        ) as rn
    from cleaned
)

select
    currency,
    currency_iso_code,
    current_date as modified_date
from ranked
where rn = 1 and currency_iso_code is not null