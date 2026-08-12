-- dim_borrower: Borrower demographic profile dimension
-- WHY: Enables slicing by employment stability, income tier, home ownership,
--      and verification — the key socioeconomic drivers of credit risk.
--      Interviewers love this because it shows you understand WHO defaults, not just WHAT defaults.

with borrower_profiles as (
    select
        borrower_key,
        home_ownership,
        verification_status,
        emp_length,
        emp_length_bucket,
        income_band,
        annual_inc,
        row_number() over (partition by borrower_key order by annual_inc desc) as rn
    from {{ ref('stg_loans') }}
    where borrower_key is not null
)

select
    borrower_key,
    home_ownership,
    verification_status,
    emp_length,
    emp_length_bucket,
    income_band,

    -- income tier ranking for BI sorting
    case
        when income_band = '<25K'      then 1
        when income_band = '25K-50K'   then 2
        when income_band = '50K-75K'   then 3
        when income_band = '75K-100K'  then 4
        when income_band = '100K-150K' then 5
        when income_band = '150K+'     then 6
    end as income_tier_rank,

    -- employment stability score (higher = more stable)
    case
        when emp_length_bucket = '10+ years' then 5
        when emp_length_bucket = '7-9 years' then 4
        when emp_length_bucket = '4-6 years' then 3
        when emp_length_bucket = '1-3 years' then 2
        when emp_length_bucket = '<1 year'   then 1
        else 0
    end as employment_stability_score,

    -- borrower trust level based on verification
    case
        when verification_status = 'Verified'        then 'High Trust'
        when verification_status = 'Source Verified'  then 'Medium Trust'
        else 'Low Trust'
    end as borrower_trust_level,

    -- housing stability indicator
    case
        when home_ownership in ('Mortgage', 'Own') then 'Stable Housing'
        when home_ownership = 'Rent'               then 'Renting'
        else 'Other/Unknown'
    end as housing_stability

from borrower_profiles
where rn = 1
