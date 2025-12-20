{{ config(
    materialized='incremental',
    unique_key='standing_key',
    incremental_strategy='merge'
) }}

with standings as (
    
    select * from {{ ref('stg_standings') }}
   {{ incremental_lookback('ingestion_date', 3) }}

),

teams as ( select * from {{ ref('dim_teams') }} ),
leagues as ( select * from {{ ref('dim_leagues') }} )

select
    -- Primary Key
    standings.standing_key,

    -- Foreign Keys
    leagues.league_key,
    teams.team_key,

    -- Facts (The Numbers)
    standings.rank,
    standings.points,
    standings.goal_diff,
    standings.form,
    standings.played,
    standings.wins,
    standings.draws,
    standings.losses,

    -- Metadata
    standings.ingestion_date as last_loaded_at

from standings
left join teams on standings.team_id = teams.team_id
left join leagues 
    on standings.league_id = leagues.league_id 
    and standings.season = leagues.season