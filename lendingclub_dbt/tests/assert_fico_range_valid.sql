-- Replaces what would otherwise need dbt_utils.accepted_range. Fails (returns
-- rows) if any loan in stg_loans has a FICO score outside 300-850, or
-- fico_range_high < fico_range_low. stg_loans should never contain these --
-- is_valid_fico is supposed to catch them upstream -- so this test is really
-- a regression check on int_loans_cleaned's validation logic.

select *
from {{ ref('stg_loans') }}
where fico_range_low not between 300 and 850
   or fico_range_high not between 300 and 850
   or fico_range_high < fico_range_low