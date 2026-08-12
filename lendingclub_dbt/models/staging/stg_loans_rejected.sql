-- Same note as stg_loans.sql: view, no config override, folder-level
-- post-hook already logs this model automatically.

-- =============================================================================
-- stg_loans_rejected
-- Rows that failed at least one DQ check. Kept (not dropped) so you have a
-- real reconciliation number: count(int_loans_cleaned) should always equal
-- count(stg_loans) + count(stg_loans_rejected). dq_fail_reasons tells you
-- exactly which check(s) each row failed.
-- =============================================================================

select *
from {{ ref('int_loans_cleaned') }}
where is_dq_passed = false