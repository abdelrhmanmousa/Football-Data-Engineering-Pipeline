{{ config(
    materialized='incremental',
    unique_key='league_key',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_fixtures') }}
),



distinct_leagues as (
    select distinct
        -- We construct the keys here
        {{ dbt_utils.generate_surrogate_key(['league_id', 'season']) }} as league_key,
        league_id,
        league_name,
        season,
        ingestion_date as last_loaded_at
    from source
    
    {{ incremental_lookback('ingestion_date', 3) }}

)

select * from distinct_leagues