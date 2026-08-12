-- dim_vintage: Vintage/cohort dimension for portfolio aging analysis
-- WHY: Vintage analysis is THE gold standard in credit risk. Every bank, every lender,
--      every credit analyst looks at loan performance by origination cohort.
--      This dimension enables vintage curves, cohort default rates, and seasoning analysis.
--      Guaranteed to impress any interviewer in the lending/fintech space.

with vintage_distinct as (
    select distinct
        vintage_quarter,
        vintage_year
    from {{ ref('stg_loans') }}
    where vintage_quarter is not null
)

select
    vintage_quarter                                             as vintage_date_key,
    vintage_year,
    'Q' || quarter(vintage_quarter)                             as vintage_quarter_label,
    vintage_year || '-Q' || quarter(vintage_quarter)            as vintage_cohort_label,

    -- vintage era (market cycle context)
    case
        when vintage_year between 2007 and 2009 then 'Financial Crisis Era'
        when vintage_year between 2010 and 2012 then 'Recovery Era'
        when vintage_year between 2013 and 2015 then 'Growth Era'
        when vintage_year between 2016 and 2018 then 'Mature Era'
        when vintage_year >= 2019               then 'Late Cycle'
        else 'Pre-Crisis'
    end as vintage_era,

    -- seasoning bucket (how old is this vintage now)
    case
        when datediff('month', vintage_quarter, current_date()) > 60 then 'Fully Seasoned (5+ yrs)'
        when datediff('month', vintage_quarter, current_date()) > 36 then 'Well Seasoned (3-5 yrs)'
        when datediff('month', vintage_quarter, current_date()) > 12 then 'Partially Seasoned (1-3 yrs)'
        else 'Fresh (<1 yr)'
    end as seasoning_bucket,

    datediff('month', vintage_quarter, current_date())          as months_on_book,

    -- economic cycle phase at origination
    case
        when vintage_year in (2008, 2009, 2020) then 'Recession Origination'
        when vintage_year in (2010, 2011, 2021) then 'Early Recovery Origination'
        else 'Expansion Origination'
    end as economic_phase_at_origination,

    -- expected maturity status
    case
        when datediff('month', vintage_quarter, current_date()) > 60 then 'All Loans Matured'
        when datediff('month', vintage_quarter, current_date()) > 36 then 'Short-Term Matured'
        else 'Still Maturing'
    end as maturity_status

from vintage_distinct
