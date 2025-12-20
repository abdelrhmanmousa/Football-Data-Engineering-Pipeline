{{ config(materialized='table') }}

with standings as (
    select distinct 
        team_id, 
        league_id, 
        season 
    from {{ ref('stg_standings') }}
),

teams as ( select * from {{ ref('dim_teams') }} ),
leagues as ( select * from {{ ref('dim_leagues') }} )

select
    {{ dbt_utils.generate_surrogate_key(['teams.team_key', 'leagues.league_key', 'standings.season']) }} as bridge_key,
    
    teams.team_key,
    leagues.league_key,
    standings.season

from standings
join teams on standings.team_id = teams.team_id
join leagues 
    on standings.league_id = leagues.league_id 
    and standings.season = leagues.season