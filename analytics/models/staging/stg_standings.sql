with source as (
    select * from {{ source('football_lake', 'raw_standings') }}
),

{% if target.type == 'duckdb' %}
-- DUCKDB: Double Unnest
flattened_groups as (
    select 
        league.id as league_id,
        league.name as league_name,
        league.country as league_country,
        league.season as season,
        -- Unnest Level 1 (Get the groups)
        Unnest(league.standings) as group_list,
        ingestion_date
    from source
),
flattened_teams as (
    select
        league_id,
        league_name,
        league_country,
        season,
        -- Unnest Level 2 (Get the teams inside the group)
        unnest(group_list) as rank_item,
        ingestion_date
    from flattened_groups
)
{% else %}
-- SNOWFLAKE: Double Lateral Flatten
flattened_teams as (
    select
        root.value:league:id::int as league_id,
        root.value:league:name::string as league_name,
        root.value:league:country::string as league_country,
        root.value:league:season::int as season,
        -- Level 2 Value
        team_flat.value as rank_item,
        to_date(split_part(metadata$filename, '=', 3), 'YYYY-MM-DD') as ingestion_date
    from source,
    lateral flatten(input => source.$1) as root,
    lateral flatten(input => root.value:league:standings) as group_flat, -- Level 1
    lateral flatten(input => group_flat.value) as team_flat            -- Level 2
)
{% endif %}

select
    {{ dbt_utils.generate_surrogate_key(['league_id', 'rank_item.team.id', 'season']) }} as standing_key,

    league_id,
    league_name,
    league_country,
    season,
    
    -- Extract from the fully flattened item
    {% if target.type == 'duckdb' %}
        rank_item.rank as rank,
        rank_item.team.id as team_id,
        rank_item.team.name as team_name,
        rank_item.points as points,
        rank_item.goalsDiff as goal_diff,
        rank_item.form as form,
        rank_item.all.played as played,
        rank_item.all.win as wins,
        rank_item.all.draw as draws,
        rank_item.all.lose as losses
    {% else %}
        rank_item:rank::int as rank,
        rank_item:team:id::int as team_id,
        rank_item:team:name::string as team_name,
        rank_item:points::int as points,
        rank_item:goalsDiff::int as goal_diff,
        rank_item:form::string as form,
        rank_item:all:played::int as played,
        rank_item:all:win::int as wins,
        rank_item:all:draw::int as draws,   
        rank_item:all:lose::int as losses
    {% endif %},
    
    ingestion_date

from flattened_teams
-- INCREMENTAL LOGIC:
-- We want the latest ranking for every team in every league
qualify row_number() over (partition by league_id, team_id order by ingestion_date desc) = 1