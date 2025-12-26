with source as (
    select * from {{ source('football_lake', 'raw_players') }}
),

{% if target.type == 'duckdb' %}
-- DUCKDB LOGIC
flattened as (
    select
        player.id as player_id,
        player.name as App_name,
        player.firstname as first_name,
        player.lastname as last_name,
        player.nationality as nationality,
        player.age as age,
        unnest(statistics) as stats,
        ingestion_date
    from source
)
{% else %}
-- SNOWFLAKE LOGIC
flattened as (
    select
        root.value:player:id::int as player_id,
        root.value:player:name::string as App_name,
        root.value:player:firstname::string as first_name,
        root.value:player:lastname::string as last_name,
        root.value:player:nationality::string as nationality,
        root.value:player:age::int as age,
        stats.value as stats,
        -- FIX: Replace metadata$filename with CURRENT_DATE()
        CURRENT_DATE() as ingestion_date
    from source,
    lateral flatten(input => source.$1) as root,
    lateral flatten(input => root.value:statistics) as stats
)
{% endif %}

select
    -- Generate Surrogate Key
    {% if target.type == 'duckdb' %}
        {{ dbt_utils.generate_surrogate_key(['player_id', 'stats.team.id', 'stats.league.name']) }} as player_stat_key,
    {% else %}
        {{ dbt_utils.generate_surrogate_key(['player_id', 'stats:team:id', 'stats:league:name']) }} as player_stat_key,
    {% endif %}

    player_id,
    App_name,
    first_name,
    last_name,
    nationality,
    age,
    
    -- Extract fields
    {% if target.type == 'duckdb' %}
        stats.team.id as team_id,
        stats.team.name as team_name,
        stats.league.name as league_name,
        stats.league.country as league_country,
        stats.league.season as league_season,
        stats.games.position as position,
        stats.goals.total as goals,
        stats.games.rating as rating,
        stats.games.minutes as minutes_played,
        stats.cards.yellow as yellow_cards,
        stats.goals.assists as assists
    {% else %}
        stats:team:id::int as team_id,
        stats:team:name::string as team_name,
        stats:league:name::string as league_name,
        stats:league:country::string as league_country,
        stats:league:season::int as league_season,
        stats:games:position::string as position,
        stats:goals:total::int as goals,
        stats:games:rating::float as rating,
        stats:games:minutes::int as minutes_played,
        stats:cards:yellow::int as yellow_cards,
        stats:goals:assists::int as assists
    {% endif %},
    
    ingestion_date

from flattened
-- INCREMENTAL LOGIC FIX:
-- We use the RAW expression (stats.team.id) instead of the alias (team_id) to avoid the Binder Error
{% if target.type == 'duckdb' %}
qualify row_number() over (partition by player_id, stats.team.id order by ingestion_date desc) = 1
{% else %}
qualify row_number() over (partition by player_id, team_id order by ingestion_date desc) = 1
{% endif %}