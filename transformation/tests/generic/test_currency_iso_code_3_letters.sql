{# 
  Generic test: Passes when every non-null currency_iso_code in the target model
  is exactly three alphabetic characters (A–Z). NULLs are allowed and ignored.
#}
{% test currency_iso_code_3_letters(model, column_name) %}

-- Fail rows where (non-null) value is not exactly three A-Z letters
select
  {{ column_name }} as currency_iso_code,
  'Must be exactly 3 letters A-Z or NULL' as violation_reason
from {{ model }}
where {{ column_name }} is not null 
  and not regexp_full_match(upper({{ column_name }}), '^[A-Z]{3}$')

{% endtest %}