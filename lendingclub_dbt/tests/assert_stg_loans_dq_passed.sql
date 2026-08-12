-- Regression check: stg_loans is defined as "where is_dq_passed = true", so
-- this should always return zero rows. If it ever doesn't, the filter in
-- stg_loans.sql was changed or broken without updating this test -- that's
-- the point of catching it here instead of in a client-facing dashboard.

select *
from {{ ref('stg_loans') }}
where is_dq_passed = false