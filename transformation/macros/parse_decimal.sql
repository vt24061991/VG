{#
  parse_decimal(expr, precision=18, scale=6)
  Parses a messy numeric string to DECIMAL(p,s):
    - If comma and no dot: comma = decimal separator
    - Else: strip commas (thousand separators)
    - Remove non [0-9 . -]
    - try_cast -> NULL on failure
  Usage: {{ parse_decimal("col", 18, 6) }} as amount 
#}
{% macro parse_decimal(expr, precision=18, scale=6) -%}
try_cast(
  regexp_replace(
    case
      when strpos({{ expr }}, ',') > 0 and strpos({{ expr }}, '.') = 0
        then replace({{ expr }}, ',', '.')
      else replace({{ expr }}, ',', '')
    end,
    '[^0-9.\\-]', ''
  ) as decimal({{ precision }}, {{ scale }})
)
{%- endmacro %}