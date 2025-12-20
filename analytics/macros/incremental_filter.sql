{% macro incremental_lookback(date_column, lookback_days) %}
{% if is_incremental() %}
where {{ date_column }} >= (
    select
        {% if target.type == 'duckdb' %}
            max(last_loaded_at) - interval '{{ lookback_days }} days'
        
        {% elif target.type == 'snowflake' %}
            dateadd(day, -{{ lookback_days }}, max(last_loaded_at))
        {% else %}
            max(last_loaded_at)
        {% endif %}
    from {{ this }}
)
{% endif %}
{% endmacro %}
