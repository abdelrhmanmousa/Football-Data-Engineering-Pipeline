{{ config(
    materialized='incremental',
    unique_key='venue_key',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_fixtures') }}
    -- Filter out null venues (sometimes TBD matches have no venue)
    where venue_id is not null
),



distinct_venues as (
    select distinct
        {{ dbt_utils.generate_surrogate_key(['venue_id']) }} as venue_key,
        venue_id,
        venue_name,
        venue_city,
        ingestion_date as last_loaded_at
    from source

    {{ incremental_lookback('ingestion_date', 3) }}

)

select * 
from distinct_venues
-- Deduplicate: If a venue name gets updated, keep the latest version
qualify row_number() over (partition by venue_id order by last_loaded_at desc) = 1