-- dim_credit_profile: Credit risk profile dimension
-- WHY: This is the HEART of credit risk analytics. Grade + FICO + risk segment
--      together define the borrower's creditworthiness tier. BI users will slice
--      EVERY metric by this dimension. Shows interviewer you understand credit scoring.

with credit_profiles as (
    select
        credit_profile_key,
        grade,
        sub_grade,
        risk_segment,
        row_number() over (partition by credit_profile_key order by sub_grade) as rn
    from {{ ref('stg_loans') }}
    where credit_profile_key is not null
)

select
    credit_profile_key,
    grade,
    sub_grade,
    risk_segment,

    -- grade ranking (for BI sorting and visual ordering)
    case
        when grade = 'A' then 1
        when grade = 'B' then 2
        when grade = 'C' then 3
        when grade = 'D' then 4
        when grade = 'E' then 5
        when grade = 'F' then 6
        when grade = 'G' then 7
    end as grade_rank,

    -- expected loss tier (what the market prices in)
    case
        when grade in ('A', 'B') then 'Investment Grade'
        when grade in ('C', 'D') then 'Near-Investment Grade'
        when grade in ('E', 'F', 'G') then 'Speculative Grade'
    end as credit_tier,

    -- risk-return profile
    case
        when risk_segment = 'Prime'         then 'Low Risk - Low Return'
        when risk_segment = 'Near-Prime'    then 'Moderate Risk - Moderate Return'
        when risk_segment = 'Subprime'      then 'High Risk - High Return'
        when risk_segment = 'Deep-Subprime' then 'Very High Risk - Very High Return'
    end as risk_return_profile,

    -- pricing strategy alignment
    case
        when grade in ('A', 'B') then 'Competitive Pricing'
        when grade in ('C', 'D') then 'Risk-Adjusted Pricing'
        when grade in ('E', 'F', 'G') then 'Premium Pricing'
    end as pricing_strategy,

    -- portfolio allocation recommendation
    case
        when grade in ('A', 'B') then 'Core Holdings (60-70%)'
        when grade in ('C', 'D') then 'Balanced Allocation (20-30%)'
        when grade in ('E', 'F', 'G') then 'Opportunistic (<10%)'
    end as allocation_guidance

from credit_profiles
where rn = 1
