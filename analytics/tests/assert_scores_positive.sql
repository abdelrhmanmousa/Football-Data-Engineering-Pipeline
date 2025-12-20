-- It is impossible to have a negative score
select *
from {{ ref('fct_matches') }}
where home_score < 0 OR away_score < 0