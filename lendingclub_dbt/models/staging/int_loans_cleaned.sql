LENDING_CLUB.SILVER.INT_LOANS_CLEANED-- No config(materialized=...) here on purpose: models/staging/+materialized: view
-- in dbt_project.yml already applies to everything in this folder, and the
-- +post-hook there already fires log_layer_audit('SILVER', this) on this model
-- automatically once it's built -- no extra wiring needed.

-- =============================================================================
-- int_loans_cleaned
-- Shared cleaning / validation / derivation layer for the credit risk mart.
-- Both stg_loans (passed rows) and stg_loans_rejected (failed rows)
-- select from this model so the DQ logic lives in exactly one place.
--
-- Column scope: the 48 columns your mentor listed, PLUS earliest_cr_line.
-- earliest_cr_line is not on the mentor's list but is required to compute
-- credit_history_years and to run "Credit History Validation" (item 27) --
-- both of which the mentor's own list asks for. Flag this explicitly in
-- your demo/README so it doesn't look like an oversight.
-- =============================================================================

with

-- ---------------------------------------------------------------------------
-- 1 & 2: COLUMN SELECTION / COLUMN EXCLUSION
-- ---------------------------------------------------------------------------
source_selected as (
    select
        id, member_id, loan_amnt, funded_amnt, funded_amnt_inv, term, int_rate,
        installment, grade, sub_grade, emp_title, emp_length, home_ownership,
        annual_inc, verification_status, issue_d, loan_status, purpose, title,
        zip_code, addr_state, dti, delinq_2yrs, fico_range_low, fico_range_high,
        inq_last_6mths, open_acc, pub_rec, revol_bal, revol_util, total_acc,
        out_prncp, total_pymnt, recoveries, application_type,
        tot_coll_amt, all_util, inq_fi, avg_cur_bal, bc_open_to_buy,
        chargeoff_within_12_mths, delinq_amnt, mort_acc, pub_rec_bankruptcies,
        tot_hi_cred_lim, total_bc_limit, hardship_flag, debt_settlement_flag,
        earliest_cr_line,          -- required support column, see header note
        _source_file, _loaded_at
    from {{ source('raw', 'loans_raw') }}
    where id is not null
),

-- ---------------------------------------------------------------------------
-- 5: DUPLICATE REMOVAL -- keep most recently loaded record per loan id
-- ---------------------------------------------------------------------------
deduped as (
    select *
    from source_selected
    qualify row_number() over (partition by id order by _loaded_at desc) = 1
),

-- ---------------------------------------------------------------------------
-- 3, 7, 8: DATA TYPE / NUMERIC / PERCENTAGE STANDARDIZATION
-- ---------------------------------------------------------------------------
numeric_standardized as (
    select
        *,
        try_to_number(loan_amnt)                       as loan_amnt_num,
        try_to_number(funded_amnt)                      as funded_amnt_num,
        try_to_number(funded_amnt_inv)                  as funded_amnt_inv_num,
        try_to_number(replace(term, ' months', ''))     as term_months,
        try_to_number(replace(int_rate, '%', ''))        as int_rate_pct,
        try_to_number(installment)                       as installment_num,
        try_to_number(annual_inc)                        as annual_inc_num,
        try_to_number(dti)                                as dti_num,
        try_to_number(delinq_2yrs)                        as delinq_2yrs_num,
        try_to_number(fico_range_low)                     as fico_low_num,
        try_to_number(fico_range_high)                    as fico_high_num,
        try_to_number(inq_last_6mths)                      as inq_last_6mths_num,
        try_to_number(open_acc)                            as open_acc_num,
        try_to_number(pub_rec)                             as pub_rec_num,
        try_to_number(revol_bal)                           as revol_bal_num,
        try_to_number(replace(revol_util, '%', ''))        as revol_util_pct,
        try_to_number(total_acc)                           as total_acc_num,
        try_to_number(out_prncp)                           as out_prncp_num,
        try_to_number(total_pymnt)                         as total_pymnt_num,
        try_to_number(recoveries)                          as recoveries_num,
        try_to_number(tot_coll_amt)                        as tot_coll_amt_num,
        try_to_number(replace(all_util, '%', ''))          as all_util_pct,
        try_to_number(inq_fi)                              as inq_fi_num,
        try_to_number(avg_cur_bal)                         as avg_cur_bal_num,
        try_to_number(bc_open_to_buy)                      as bc_open_to_buy_num,
        try_to_number(chargeoff_within_12_mths)            as chargeoff_within_12_mths_num,
        try_to_number(delinq_amnt)                         as delinq_amnt_num,
        try_to_number(mort_acc)                            as mort_acc_num,
        try_to_number(pub_rec_bankruptcies)                as pub_rec_bankruptcies_num,
        try_to_number(tot_hi_cred_lim)                     as tot_hi_cred_lim_num,
        try_to_number(total_bc_limit)                      as total_bc_limit_num
    from deduped
),

-- ---------------------------------------------------------------------------
-- 4, 30: DATE STANDARDIZATION / LOAN DATE VALIDATION (support)
-- ---------------------------------------------------------------------------
date_standardized as (
    select
        *,
        try_to_date(issue_d, 'MON-YYYY')          as issue_date,
        try_to_date(earliest_cr_line, 'MON-YYYY') as earliest_cr_line_date
    from numeric_standardized
),

-- ---------------------------------------------------------------------------
-- 9, 24, 25, 26: TEXT / HOME OWNERSHIP / VERIFICATION / APPLICATION TYPE
--                STANDARDIZATION
-- ---------------------------------------------------------------------------
text_standardized as (
    select
        *,
        upper(trim(grade))                  as grade_clean,
        upper(trim(sub_grade))              as sub_grade_clean,
        nullif(trim(emp_title), '')         as emp_title_clean,
        nullif(trim(title), '')             as title_clean,
        initcap(trim(home_ownership))       as home_ownership_clean,
        initcap(trim(verification_status))  as verification_status_clean,
        initcap(trim(purpose))              as purpose_clean,
        upper(trim(addr_state))             as addr_state_clean,
        initcap(trim(application_type))     as application_type_clean,
        upper(trim(hardship_flag))          as hardship_flag_clean,
        upper(trim(debt_settlement_flag))   as debt_settlement_flag_clean
    from date_standardized
),

-- ---------------------------------------------------------------------------
-- 20: ZIP CODE STANDARDIZATION -- source is already masked to "190xx"
-- ---------------------------------------------------------------------------
zip_standardized as (
    select *, upper(trim(zip_code)) as zip_code_clean
    from text_standardized
),

-- ---------------------------------------------------------------------------
-- 6: MISSING VALUE HANDLING -- business-appropriate defaults, not raw nulls
-- ---------------------------------------------------------------------------
missing_handled as (
    select
        *,
        coalesce(emp_length, 'Unknown')            as emp_length_filled,
        coalesce(dti_num, 0)                       as dti_filled,
        coalesce(mort_acc_num, 0)                  as mort_acc_filled,
        coalesce(pub_rec_bankruptcies_num, 0)      as pub_rec_bankruptcies_filled,
        coalesce(tot_coll_amt_num, 0)               as tot_coll_amt_filled,
        coalesce(delinq_amnt_num, 0)                as delinq_amnt_filled
    from zip_standardized
),

-- ---------------------------------------------------------------------------
-- 21: LOAN TERM STANDARDIZATION / 32-34: VINTAGE & LOAN AGE DERIVATION /
-- 16, 35: RISK SEGMENT & other business derivations
-- ---------------------------------------------------------------------------
enriched as (
    select
        *,
        round((fico_low_num + fico_high_num) / 2, 0)               as fico_avg,
        datediff('year', earliest_cr_line_date, issue_date)         as credit_history_years,
        year(issue_date)                                            as vintage_year,
        date_trunc('quarter', issue_date)                           as vintage_quarter,
        datediff('month', issue_date, current_date())               as loan_age_months,

        case
            when loan_status in ('Charged Off', 'Default',
                 'Does not meet the credit policy. Status:Charged Off') then 1
            else 0
        end as is_default,

        case
            when round((fico_low_num + fico_high_num) / 2, 0) >= 720 then 'Prime'
            when round((fico_low_num + fico_high_num) / 2, 0) >= 660 then 'Near-Prime'
            when round((fico_low_num + fico_high_num) / 2, 0) >= 600 then 'Subprime'
            else 'Deep-Subprime'
        end as risk_segment,

        case
            when annual_inc_num < 25000  then '<25K'
            when annual_inc_num < 50000  then '25K-50K'
            when annual_inc_num < 75000  then '50K-75K'
            when annual_inc_num < 100000 then '75K-100K'
            when annual_inc_num < 150000 then '100K-150K'
            else '150K+'
        end as income_band,

        case
            when emp_length_filled like '<%' or emp_length_filled = '0 years' then '<1 year'
            when emp_length_filled in ('1 years','2 years','3 years') then '1-3 years'
            when emp_length_filled in ('4 years','5 years','6 years') then '4-6 years'
            when emp_length_filled in ('7 years','8 years','9 years') then '7-9 years'
            when emp_length_filled = '10+ years' then '10+ years'
            else 'Unknown'
        end as emp_length_bucket,

        case
            when upper(trim(addr_state)) in ('CT','ME','MA','NH','RI','VT','NJ','NY','PA') then 'Northeast'
            when upper(trim(addr_state)) in ('IL','IN','MI','OH','WI','IA','KS','MN','MO','NE','ND','SD') then 'Midwest'
            when upper(trim(addr_state)) in ('DE','FL','GA','MD','NC','SC','VA','DC','WV','AL','KY','MS','TN','AR','LA','OK','TX') then 'South'
            when upper(trim(addr_state)) in ('AZ','CO','ID','MT','NV','NM','UT','WY','AK','CA','HI','OR','WA') then 'West'
            else 'Other'
        end as us_region,

        case
            when initcap(trim(purpose)) in ('Debt_consolidation','Credit_card') then 'Debt Related'
            when initcap(trim(purpose)) in ('Home_improvement','Major_purchase','Car','House') then 'Major Purchase'
            when initcap(trim(purpose)) in ('Small_business') then 'Business'
            when initcap(trim(purpose)) in ('Medical','Moving','Vacation','Wedding') then 'Personal'
            else 'Other'
        end as purpose_category,

        case
            when try_to_number(replace(int_rate, '%', '')) < 10 then 'Low (<10%)'
            when try_to_number(replace(int_rate, '%', '')) < 20 then 'Medium (10-20%)'
            else 'High (20%+)'
        end as int_rate_band,

        case
            when try_to_number(replace(revol_util, '%', '')) < 30 then 'Low (<30%)'
            when try_to_number(replace(revol_util, '%', '')) < 70 then 'Moderate (30-70%)'
            else 'High (70%+)'
        end as revol_util_band

    from missing_handled
),

-- ---------------------------------------------------------------------------
-- 10-17, 22, 27-29: ALL FIELD-LEVEL VALIDATION FLAGS
-- (loan status, FICO, financials, DTI, interest rate, credit utilization,
--  loan amount, payment, loan grade, credit history, revolving credit,
--  credit accounts)
-- ---------------------------------------------------------------------------
validated as (
    select
        *,

        -- 19: STATE CODE VALIDATION
        case when addr_state_clean in (
            'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA',
            'KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
            'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN','TX','UT','VT',
            'VA','WA','WV','WI','WY','DC'
        ) then true else false end as is_valid_state,

        -- 10: LOAN STATUS VALIDATION
        case when loan_status in (
            'Fully Paid','Current','Charged Off','Late (31-120 days)','In Grace Period',
            'Late (16-30 days)','Does not meet the credit policy. Status:Fully Paid',
            'Does not meet the credit policy. Status:Charged Off','Default'
        ) then true else false end as is_valid_loan_status,

        -- 22: LOAN GRADE VALIDATION
        case when grade_clean in ('A','B','C','D','E','F','G') then true else false end as is_valid_grade,

        -- 11: FICO VALIDATION
        case when fico_low_num between 300 and 850
              and fico_high_num between 300 and 850
              and fico_high_num >= fico_low_num
             then true else false end as is_valid_fico,

        -- 12, 16: FINANCIAL VALUE / LOAN AMOUNT VALIDATION
        case when loan_amnt_num > 0
              and funded_amnt_num > 0
              and funded_amnt_num <= loan_amnt_num
              and funded_amnt_inv_num <= funded_amnt_num * 1.01
             then true else false end as is_valid_financials,

        case when loan_amnt_num between 500 and 50000 then true else false end as is_valid_loan_amnt,

        -- 13: DTI VALIDATION (DTI is a ratio; treat negative or absurd (>200) as bad data)
        case when dti_num is null or (dti_num >= 0 and dti_num < 200) then true else false end as is_valid_dti,

        -- 14: INTEREST RATE VALIDATION (LendingClub range is roughly 5-31%)
        case when int_rate_pct between 0 and 40 then true else false end as is_valid_int_rate,

        -- 15: CREDIT UTILIZATION VALIDATION
        case when revol_util_pct is null or (revol_util_pct >= 0 and revol_util_pct <= 150)
             then true else false end as is_valid_revol_util,

        -- 17: PAYMENT VALIDATION
        case when total_pymnt_num >= 0
              and out_prncp_num >= 0
              and out_prncp_num <= funded_amnt_num * 1.01
             then true else false end as is_valid_payment,

        -- 27: CREDIT HISTORY VALIDATION
        case when earliest_cr_line_date is not null
              and earliest_cr_line_date <= issue_date
             then true else false end as is_valid_credit_history,

        -- 28: REVOLVING CREDIT VALIDATION
        case when revol_bal_num >= 0 then true else false end as is_valid_revolving,

        -- 29: CREDIT ACCOUNT VALIDATION
        case when open_acc_num >= 0
              and pub_rec_num >= 0
              and (total_acc_num is null or open_acc_num <= total_acc_num)
             then true else false end as is_valid_credit_accounts,

        -- 30: LOAN DATE VALIDATION
        case when issue_date is not null and issue_date <= current_date()
             then true else false end as is_valid_loan_date

    from enriched
),

-- ---------------------------------------------------------------------------
-- 36, 37: BUSINESS RULE VALIDATION / OVERALL DATA QUALITY CHECK
-- Roll every individual flag into one pass/fail plus a human-readable
-- reason list, so quarantined rows are actually debuggable later.
-- ---------------------------------------------------------------------------
quality_checked as (
    select
        *,
        (is_valid_state and is_valid_loan_status and is_valid_grade and is_valid_fico
         and is_valid_financials and is_valid_loan_amnt and is_valid_dti and is_valid_int_rate
         and is_valid_revol_util and is_valid_payment and is_valid_credit_history
         and is_valid_revolving and is_valid_credit_accounts and is_valid_loan_date)
            as is_dq_passed,

        array_to_string(array_construct_compact(
            case when not is_valid_state then 'invalid_state' end,
            case when not is_valid_loan_status then 'invalid_loan_status' end,
            case when not is_valid_grade then 'invalid_grade' end,
            case when not is_valid_fico then 'invalid_fico' end,
            case when not is_valid_financials then 'invalid_financials' end,
            case when not is_valid_loan_amnt then 'invalid_loan_amount' end,
            case when not is_valid_dti then 'invalid_dti' end,
            case when not is_valid_int_rate then 'invalid_int_rate' end,
            case when not is_valid_revol_util then 'invalid_revol_util' end,
            case when not is_valid_payment then 'invalid_payment' end,
            case when not is_valid_credit_history then 'invalid_credit_history' end,
            case when not is_valid_revolving then 'invalid_revolving_balance' end,
            case when not is_valid_credit_accounts then 'invalid_credit_accounts' end,
            case when not is_valid_loan_date then 'invalid_loan_date' end
        ), ', ') as dq_fail_reasons

    from validated
)

-- ---------------------------------------------------------------------------
-- 39, 40: AUDIT COLUMN ADDITION / FINAL SCHEMA STANDARDIZATION
-- ---------------------------------------------------------------------------
select
    id                              as loan_id,
    member_id,
    loan_amnt_num                   as loan_amnt,
    funded_amnt_num                 as funded_amnt,
    funded_amnt_inv_num             as funded_amnt_inv,
    term_months,
    int_rate_pct                    as int_rate,
    installment_num                 as installment,
    grade_clean                     as grade,
    sub_grade_clean                 as sub_grade,
    emp_title_clean                 as emp_title,
    emp_length_filled               as emp_length,
    emp_length_bucket,
    home_ownership_clean            as home_ownership,
    annual_inc_num                  as annual_inc,
    income_band,
    verification_status_clean       as verification_status,
    issue_date,
    vintage_year,
    vintage_quarter,
    loan_age_months,
    loan_status,
    purpose_clean                   as purpose,
    purpose_category,
    title_clean                     as title,
    dti_filled                      as dti,
    delinq_2yrs_num                 as delinq_2yrs,
    earliest_cr_line_date,
    credit_history_years,
    fico_low_num                    as fico_range_low,
    fico_high_num                   as fico_range_high,
    fico_avg,
    risk_segment,
    inq_last_6mths_num              as inq_last_6mths,
    open_acc_num                    as open_acc,
    pub_rec_num                     as pub_rec,
    revol_bal_num                   as revol_bal,
    revol_util_pct                  as revol_util,
    revol_util_band,
    total_acc_num                   as total_acc,
    out_prncp_num                   as outstanding_principal,
    total_pymnt_num                 as total_pymnt,
    recoveries_num                  as recoveries,
    application_type_clean          as application_type,
    tot_coll_amt_filled             as tot_coll_amt,
    all_util_pct                    as all_util,
    inq_fi_num                      as inq_fi,
    avg_cur_bal_num                 as avg_cur_bal,
    bc_open_to_buy_num              as bc_open_to_buy,
    chargeoff_within_12_mths_num    as chargeoff_within_12_mths,
    delinq_amnt_filled              as delinq_amnt,
    mort_acc_filled                 as mort_acc,
    pub_rec_bankruptcies_filled     as pub_rec_bankruptcies,
    tot_hi_cred_lim_num             as tot_hi_cred_lim,
    total_bc_limit_num              as total_bc_limit,
    hardship_flag_clean             as hardship_flag,
    debt_settlement_flag_clean      as debt_settlement_flag,
    addr_state_clean                as addr_state,
    us_region,
    zip_code_clean                  as zip_code,
    is_default,
    int_rate_band,

    -- composite dimension keys for downstream gold-layer joins
    home_ownership_clean || '||' || verification_status_clean || '||' || emp_length_bucket || '||' || income_band as borrower_key,
    grade_clean || '||' || risk_segment as credit_profile_key,
    term_months || '||' || int_rate_band || '||' || application_type_clean as loan_terms_key,

    -- DQ / audit
    is_valid_state, is_valid_loan_status, is_valid_grade, is_valid_fico, is_valid_financials,
    is_valid_loan_amnt, is_valid_dti, is_valid_int_rate, is_valid_revol_util, is_valid_payment,
    is_valid_credit_history, is_valid_revolving, is_valid_credit_accounts, is_valid_loan_date,
    is_dq_passed,
    dq_fail_reasons,
    _source_file,
    _loaded_at,
    current_timestamp()             as _silver_processed_at

from quality_checked