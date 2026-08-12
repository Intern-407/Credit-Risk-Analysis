-- fct_loans: Central fact table for the credit risk star schema
-- WHY: This is the grain-level transactional fact. One row per loan, linked to all
--      dimensions via foreign keys. Contains ONLY measures and keys — no descriptive
--      attributes. This is textbook Kimball star schema design.

select
    -- Primary key
    loan_id,

    -- Dimension foreign keys
    issue_date                  as date_key,
    borrower_key,
    credit_profile_key,
    loan_terms_key,
    addr_state                  as state_code,
    purpose                     as purpose_name,
    loan_status                 as status_name,
    vintage_quarter             as vintage_date_key,

    -- Core financial measures (additive facts)
    loan_amnt,
    funded_amnt,
    installment,
    int_rate,
    annual_inc,
    dti,
    outstanding_principal,
    total_pymnt,
    recoveries,

    -- Credit measures
    fico_avg,
    fico_range_low,
    fico_range_high,
    credit_history_years,
    open_acc,
    total_acc,
    revol_bal,
    revol_util,
    pub_rec,
    pub_rec_bankruptcies,
    mort_acc,
    delinq_2yrs,
    inq_last_6mths,

    -- Risk indicators (semi-additive)
    is_default,

    -- Derived measures for BI aggregation
    loan_amnt * int_rate / 100                      as expected_annual_interest,
    case when is_default = 1
         then loan_amnt - total_pymnt - recoveries
         else 0
    end                                             as net_loss_amount,
    case when is_default = 1
         then round((loan_amnt - total_pymnt - recoveries) / nullif(loan_amnt, 0), 4)
         else 0
    end                                             as loss_given_default,
    total_pymnt / nullif(funded_amnt, 0)            as repayment_ratio,

    -- Audit
    _loaded_at,
    current_timestamp()                             as _gold_processed_at

from {{ ref('stg_loans') }}
