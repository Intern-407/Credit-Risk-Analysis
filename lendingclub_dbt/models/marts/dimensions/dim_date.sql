-- dim_date: Calendar dimension for time-based BI slicing (issue date grain)
-- WHY: Enables year/quarter/month/week/day-of-week analysis, seasonality detection,
--      fiscal alignment, and vintage cohort joins without runtime date logic.

with date_spine as (
    select distinct issue_date as date_key
    from {{ ref('stg_loans') }}
    where issue_date is not null
)

select
    date_key,
    year(date_key)                                              as calendar_year,
    quarter(date_key)                                           as calendar_quarter,
    month(date_key)                                             as calendar_month,
    monthname(date_key)                                         as month_name,
    day(date_key)                                               as day_of_month,
    dayofweek(date_key)                                         as day_of_week,
    dayname(date_key)                                           as day_name,
    weekofyear(date_key)                                        as week_of_year,
    year(date_key) || '-Q' || quarter(date_key)                 as year_quarter_label,
    to_char(date_key, 'YYYY-MM')                                as year_month_label,
    date_trunc('quarter', date_key)                             as quarter_start_date,
    last_day(date_key, 'quarter')                               as quarter_end_date,
    case when month(date_key) <= 6 then 'H1' else 'H2' end     as half_year,
    case
        when month(date_key) in (12, 1, 2) then 'Winter'
        when month(date_key) in (3, 4, 5)  then 'Spring'
        when month(date_key) in (6, 7, 8)  then 'Summer'
        else 'Fall'
    end                                                         as season,
    datediff('month', date_key, current_date())                 as months_since_issue

from date_spine
