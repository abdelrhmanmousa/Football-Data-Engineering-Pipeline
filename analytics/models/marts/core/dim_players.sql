{{ config(
    materialized='incremental',
    unique_key='player_key',
    incremental_strategy='merge'
) }}

with source as (
    select * from {{ ref('stg_players') }}
),



distinct_players as (
    select distinct
        {{ dbt_utils.generate_surrogate_key(['player_id']) }} as player_key,
        player_id,
        App_name ,
        first_name,
        last_name,
        nationality,
        age,
        position,  
        goals,
        assists,
        rating,
        minutes_played,
        yellow_cards,
        ingestion_date as last_loaded_at
    from source

    {{ incremental_lookback('ingestion_date', 3) }}

)

select * 
from distinct_players
-- Deduplicate: Players appear multiple times (once per league/team stat). 
-- We just want their unique profile.
qualify row_number() over (partition by player_id order by last_loaded_at desc) = 1