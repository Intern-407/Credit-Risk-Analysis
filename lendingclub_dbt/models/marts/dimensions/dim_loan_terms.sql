-- dim_loan_terms: Loan origination / product terms dimension
-- WHY: The loan's structural terms (rate, term, amount tier) define the PRODUCT.
--      This is your product dimension — interviewers expect star schemas to separate
--      product characteristics from customer characteristics. Enables product-mix analysis.

with terms_distinct as (
    select distinct
        loan_terms_key,
        term_months,
        int_rate_band,
        application_type
    from {{ ref('stg_loans') }}
    where loan_terms_key is not null
)

select
    loan_terms_key,
    term_months,
    int_rate_band,
    application_type,

    -- term label for BI display
    case
        when term_months = 36 then 'Short Term (36 months)'
        when term_months = 60 then 'Long Term (60 months)'
        else term_months || ' months'
    end as term_label,

    -- rate environment classification
    case
        when int_rate_band = 'Low (<10%)'      then 'Low Rate Environment'
        when int_rate_band = 'Medium (10-20%)'  then 'Standard Rate'
        when int_rate_band = 'High (20%+)'      then 'High Rate / Subprime'
    end as rate_environment,

    -- product complexity
    case
        when application_type = 'Joint' then 'Joint Application'
        else 'Individual Application'
    end as application_complexity,

    -- expected prepayment behavior
    case
        when term_months = 36 and int_rate_band = 'Low (<10%)' then 'Low Prepay Risk'
        when term_months = 60 and int_rate_band = 'High (20%+)' then 'High Prepay Risk'
        else 'Moderate Prepay Risk'
    end as prepayment_expectation,

    -- margin contribution tier
    case
        when int_rate_band = 'High (20%+)' and term_months = 60 then 'Highest Margin'
        when int_rate_band = 'High (20%+)' and term_months = 36 then 'High Margin'
        when int_rate_band = 'Medium (10-20%)'                   then 'Standard Margin'
        else 'Low Margin'
    end as margin_tier,

    -- duration risk
    case
        when term_months = 60 then 'Higher Duration Risk'
        else 'Lower Duration Risk'
    end as duration_risk

from terms_distinct
