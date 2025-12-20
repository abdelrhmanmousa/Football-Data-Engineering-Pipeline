{{ config(materialized='table') }}

with player_stats as (
    select * from {{ ref('fct_player_season_stats') }}
),

players as ( select * from {{ ref('dim_players') }} ),
teams as ( select * from {{ ref('dim_teams') }} )

select 
    stats.player_key,
    p.first_name,
    p.last_name,
    
    -- Using LIST_AGG (DuckDB) or LISTAGG (Snowflake) to show all teams
    {% if target.type == 'duckdb' %}
    string_agg(t.team_name, ' -> ') as teams_played_for,
    {% else %}
    listagg(t.team_name, ' -> ') as teams_played_for,
    {% endif %}
    
    count(distinct stats.team_key) as team_count

from player_stats stats
join players p on stats.player_key = p.player_key
join teams t on stats.team_key = t.team_key

group by stats.player_key, p.first_name, p.last_name
-- Filter: Only show players who played for more than 1 team
having count(distinct stats.team_key) > 1