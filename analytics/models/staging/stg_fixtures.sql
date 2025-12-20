with source as (
    select * from {{ source('football_lake', 'raw_fixtures') }}
),

flattened as (
    -- DUCKDB: Reads JSON list automatically as rows
    {% if target.type == 'duckdb' %}
    select
        {{ dbt_utils.generate_surrogate_key(['fixture.id', 'league.id', 'league.season']) }} as fixture_key,

        fixture.id as fixture_id,
        fixture.date::timestamp as match_date,

        league.id as league_id,
        league.season as season,
        league.name as league_name,
        league.country as league_country,

        teams.home.id as home_team_id,
        teams.home.name as home_team_name,
        teams.away.id as away_team_id,
        teams.away.name as away_team_name,

        goals.home as home_score,
        goals.away as away_score,

        fixture.venue.id as venue_id,
        fixture.venue.name as venue_name,
        fixture.venue.city as venue_city,

        fixture.status.short as match_status,
        -- DuckDB automatically extracts 'ingestion_date' from the folder path (hive partitioning)
        ingestion_date 
    from source
    
    -- SNOWFLAKE: Needs to flatten the root variant column
    {% else %}
    select
        {{ dbt_utils.generate_surrogate_key(['fixture.id', 'league.id', 'league.season']) }} as fixture_key,

        value:fixture:id::int as fixture_id,
        value:fixture:date::timestamp as match_date,
        
        value:league:id::int as league_id,
        value:league:name::string as league_name,
        value:league:country::string as league_country,
        value:league:season::int as season,

        value:teams:home:id::int as home_team_id,
        value:teams:home:name::string as home_team_name,
        value:teams:away:id::int as away_team_id,
        value:teams:away:name::string as away_team_name,

        value:goals:home::int as home_score,
        value:goals:away::int as away_score,

        value:fixture:venue:id::int as venue_id,
        value:fixture:venue:name::string as venue_name,
        value:fixture:venue:city::string as venue_city,

        value:fixture:status:short::string as match_status,
        -- Snowflake parsing from filename/metadata
        to_date(split_part(metadata$filename, '=', 3), 'YYYY-MM-DD') as ingestion_date
    from source,
    lateral flatten(input => source.$1)
    {% endif %}
)

select * from flattened
-- INCREMENTAL LOGIC: Deduplicate
-- If we ingested the same match twice, keep the latest one
qualify row_number() over (partition by fixture_id order by ingestion_date desc) = 1

