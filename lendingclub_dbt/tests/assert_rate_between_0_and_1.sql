select *
from {{ ref('mart_vintage_performance') }}
where default_rate < 0 or default_rate > 1