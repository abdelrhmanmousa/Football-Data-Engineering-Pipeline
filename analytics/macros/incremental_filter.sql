{% macro incremental_lookback(date_column, lookback_days) %}
{% if is_incremental() %}
where {{ date_column }} >= (
    select
        {% if target.type == 'duckdb' %}
            coalesce(max(last_loaded_at), '1900-01-01') - interval '{{ lookback_days }} days'
        
        {% elif target.type == 'snowflake' %}
            -- Coalesce ensures that if the table is empty, it uses 1900-01-01
            dateadd(day, -{{ lookback_days }}, coalesce(max(last_loaded_at), '1900-01-01'::date))
        {% else %}
            coalesce(max(last_loaded_at), '1900-01-01')
        {% endif %}
    from {{ this }}
)
{% endif %}
{% endmacro %}