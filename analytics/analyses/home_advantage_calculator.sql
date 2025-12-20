with matches as (
    select * from {{ ref('fct_matches') }}
),
teams as (
    select * from {{ ref('dim_teams') }}
)

select 
    t.team_name,
    
    -- Calculate Win Rates
    count(case when m.home_team_key = t.team_key and m.home_score > m.away_score then 1 end) as home_wins,
    count(case when m.away_team_key = t.team_key and m.away_score > m.home_score then 1 end) as away_wins,
    
    -- Home Advantage Metric (Simple difference)
    (count(case when m.home_team_key = t.team_key and m.home_score > m.away_score then 1 end) - 
     count(case when m.away_team_key = t.team_key and m.away_score > m.home_score then 1 end)) as home_advantage_score

from teams t
join matches m on (m.home_team_key = t.team_key OR m.away_team_key = t.team_key)
group by t.team_name
having count(m.fixture_id) > 10 -- Only teams with enough games
order by home_advantage_score desc