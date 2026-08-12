-- dim_purpose: Loan purpose dimension for intent-based segmentation
-- WHY: Loan purpose is the #1 predictor of borrower behavior after FICO.
--      Debt consolidation borrowers behave differently from small business owners.
--      This dimension enables purpose-driven portfolio strategy in BI dashboards.

with purpose_distinct as (
    select distinct
        purpose,
        purpose_category
    from {{ ref('stg_loans') }}
    where purpose is not null
)

select
    purpose                                                     as purpose_name,
    purpose_category,

    -- risk expectation by purpose (industry knowledge)
    case
        when purpose in ('Small_business')                         then 'High Risk'
        when purpose in ('Debt_consolidation', 'Credit_card')      then 'Medium Risk'
        when purpose in ('Home_improvement', 'Major_purchase')     then 'Low-Medium Risk'
        when purpose in ('Wedding', 'Vacation')                    then 'Discretionary Risk'
        else 'Standard Risk'
    end as purpose_risk_expectation,

    -- borrower intent classification
    case
        when purpose_category = 'Debt Related'    then 'Refinancing Existing Debt'
        when purpose_category = 'Major Purchase'  then 'Asset Acquisition'
        when purpose_category = 'Business'        then 'Business Investment'
        when purpose_category = 'Personal'        then 'Personal Consumption'
        else 'Unclassified'
    end as borrower_intent,

    -- strategic portfolio bucket
    case
        when purpose_category = 'Debt Related'    then 'Core Portfolio'
        when purpose_category = 'Major Purchase'  then 'Growth Portfolio'
        when purpose_category = 'Business'        then 'High-Yield Portfolio'
        else 'Diversification Portfolio'
    end as portfolio_strategy_bucket,

    -- typical loan size expectation
    case
        when purpose in ('Debt_consolidation', 'Small_business', 'Home_improvement') then 'Large Ticket'
        when purpose in ('Credit_card', 'Car', 'Major_purchase')                      then 'Medium Ticket'
        else 'Small Ticket'
    end as typical_loan_size

from purpose_distinct
