-- No config here either -- staging/+materialized: view and the folder-level
-- post-hook apply automatically. Kept as a view (not overridden to table) to
-- match your project's own convention: staging stays light, marts are the
-- physical tables. This also matters on a free-trial account -- fewer
-- materialized tables recomputing means fewer credits burned on your daily
-- schedule.

-- =============================================================================
-- stg_loans
-- Clean, validated, enriched, analysis-ready loan records. Every row here
-- has passed all data quality checks (is_dq_passed = true). This is the
-- table your marts/ (Gold layer) models should read from.
-- =============================================================================

select *
from {{ ref('int_loans_cleaned') }}
where is_dq_passed = true