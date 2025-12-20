{{ config(
    materialized='incremental',
    unique_key='fixture_key',
    incremental_strategy='merge'
) }}

with fixtures as (
    select * from {{ ref('stg_fixtures') }}
    
    {{ incremental_lookback('ingestion_date', 3) }}

),

leagues as (
    select * from {{ ref('dim_leagues') }}
),

teams as (
    select * from {{ ref('dim_teams') }}
)

select
    -- Primary Key
    fixtures.fixture_key,
    
    -- IDs
    fixtures.fixture_id,
    leagues.league_key,
    
    -- Use COALESCE to handle missing teams (avoid NULLs in Fact tables)
    coalesce(home_team.team_key, '-1') as home_team_key,
    coalesce(away_team.team_key, '-1') as away_team_key,

    -- Facts
    fixtures.home_score,
    fixtures.away_score,
    (fixtures.home_score + fixtures.away_score) as total_goals,
    
    fixtures.match_status,
    fixtures.match_date,
    
    -- Watermark
    fixtures.ingestion_date as last_loaded_at

from fixtures

left join leagues 
    on fixtures.league_id = leagues.league_id 
    and fixtures.season = leagues.season

left join teams as home_team 
    on fixtures.home_team_id = home_team.team_id

left join teams as away_team 
    on fixtures.away_team_id = away_team.team_id