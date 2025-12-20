{{ config(
    materialized='incremental',
    unique_key='team_key',
    incremental_strategy='merge'
) }}

-- 1. Gather all potential teams from all sources
with fixtures as (
    select * from {{ ref('stg_fixtures') }}
),

standings as (
    select * from {{ ref('stg_standings') }}
),



combined_teams as (
    -- Get Home Teams
    select 
        home_team_id as team_id, 
        home_team_name as team_name, 
        ingestion_date 
    from fixtures
    
    union all
    
    -- Get Away Teams
    select 
        away_team_id as team_id, 
        away_team_name as team_name, 
        ingestion_date 
    from fixtures
    
    union all
    
    -- Get Standings Teams
    select 
        team_id, 
        team_name, 
        ingestion_date 
        
    from standings
),

unique_teams as (
    select
        {{ dbt_utils.generate_surrogate_key(['team_id']) }} as team_key,
        team_id,
        team_name,
        ingestion_date as last_loaded_at
    from combined_teams
    
    {{ incremental_lookback('ingestion_date', 3) }}

)

select * 
from unique_teams
-- Deduplicate: If a team appears in multiple files today, take one.
qualify row_number() over (partition by team_id order by last_loaded_at desc) = 1