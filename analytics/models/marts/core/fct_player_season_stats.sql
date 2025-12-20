{{ config(
    materialized='incremental',
    unique_key='player_stat_key',
    incremental_strategy='merge'
) }}

with stats as (
    select * from {{ ref('stg_players') }}
    {{ incremental_lookback('ingestion_date', 3) }}
),

players as ( select * from {{ ref('dim_players') }} ),
teams as ( select * from {{ ref('dim_teams') }} )

select
    -- Primary Key (Generated in Staging: Player + Team + Season)
    stats.player_stat_key,
    
    -- Dimensions
    players.player_key,
    teams.team_key,
    
    -- Metrics
    stats.position,
    stats.goals,
    -- If you extract these in staging, add them here:
    stats.assists,
    stats.yellow_cards,
    stats.minutes_played,
    stats.rating, 
    
    -- Metadata
    stats.league_name,
    stats.ingestion_date as last_loaded_at

from stats
left join players on stats.player_id = players.player_id
left join teams on stats.team_id = teams.team_id