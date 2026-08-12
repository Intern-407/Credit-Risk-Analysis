-- Row-count reconciliation as an automated test, not a manual screenshot:
-- total rows in int_loans_cleaned must equal passed (stg_loans) + rejected
-- (stg_loans_rejected). Returns a row (fails) only on mismatch.

with total as (
    select count(*) as total_rows from {{ ref('int_loans_cleaned') }}
),
split as (
    select
        (select count(*) from {{ ref('stg_loans') }})
      + (select count(*) from {{ ref('stg_loans_rejected') }}) as split_rows
)
select *
from total
cross join split
where total.total_rows != split.split_rows