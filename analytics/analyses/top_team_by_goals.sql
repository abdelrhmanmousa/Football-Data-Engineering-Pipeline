-- analyses/top_teams_by_goals.sql
select
    t.team_name,
    sum(f.total_goals) as goals
from {{ ref('fct_matches') }} f
join {{ ref('dim_teams') }} t
    on f.home_team_key = t.team_key
group by 1
order by goals desc;
limit 10;