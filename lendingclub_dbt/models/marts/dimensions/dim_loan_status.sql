-- dim_loan_status: Loan performance/status dimension
-- WHY: This is the outcome dimension — it classifies WHERE each loan sits in its lifecycle.
--      Essential for BI dashboards showing portfolio health, delinquency funnels,
--      and loss severity analysis. Interviewers expect you to model loan states as a dimension.

with status_distinct as (
    select distinct loan_status
    from {{ ref('stg_loans') }}
    where loan_status is not null
)

select
    loan_status                                                 as status_name,

    -- performance classification (the most important column for credit risk BI)
    case
        when loan_status = 'Fully Paid'         then 'Performing - Closed'
        when loan_status = 'Current'            then 'Performing - Active'
        when loan_status = 'In Grace Period'    then 'Early Delinquency'
        when loan_status = 'Late (16-30 days)'  then 'Delinquent - 30 DPD'
        when loan_status = 'Late (31-120 days)' then 'Delinquent - 60+ DPD'
        when loan_status in ('Charged Off', 'Default',
             'Does not meet the credit policy. Status:Charged Off') then 'Loss'
        when loan_status = 'Does not meet the credit policy. Status:Fully Paid' then 'Performing - Legacy'
    end as performance_category,

    -- is the loan still active?
    case
        when loan_status in ('Current', 'In Grace Period', 'Late (16-30 days)', 'Late (31-120 days)')
        then true else false
    end as is_active,

    -- binary default flag
    case
        when loan_status in ('Charged Off', 'Default',
             'Does not meet the credit policy. Status:Charged Off') then true
        else false
    end as is_defaulted,

    -- delinquency stage (for funnel analysis)
    case
        when loan_status = 'Current'            then 0
        when loan_status = 'Fully Paid'         then 0
        when loan_status = 'In Grace Period'    then 1
        when loan_status = 'Late (16-30 days)'  then 2
        when loan_status = 'Late (31-120 days)' then 3
        when loan_status in ('Charged Off', 'Default',
             'Does not meet the credit policy. Status:Charged Off') then 4
        else 0
    end as delinquency_stage,

    -- severity bucket for loss analysis
    case
        when loan_status in ('Fully Paid', 'Current') then 'No Loss'
        when loan_status in ('In Grace Period', 'Late (16-30 days)') then 'Potential Loss'
        when loan_status = 'Late (31-120 days)' then 'Probable Loss'
        when loan_status in ('Charged Off', 'Default',
             'Does not meet the credit policy. Status:Charged Off') then 'Confirmed Loss'
        else 'No Loss'
    end as loss_severity_bucket,

    -- regulatory reporting classification (Basel alignment)
    case
        when loan_status in ('Charged Off', 'Default',
             'Does not meet the credit policy. Status:Charged Off') then 'Stage 3 - Credit Impaired'
        when loan_status in ('Late (31-120 days)') then 'Stage 2 - Significant Increase'
        when loan_status in ('In Grace Period', 'Late (16-30 days)') then 'Stage 2 - Watch List'
        else 'Stage 1 - Performing'
    end as ifrs9_stage

from status_distinct
