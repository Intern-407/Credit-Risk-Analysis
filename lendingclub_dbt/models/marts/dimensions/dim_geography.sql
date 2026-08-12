-- dim_geography: Geographic dimension for regional risk analysis (state grain)
-- WHY: Credit risk varies dramatically by region — regulatory environments differ,
--      cost of living impacts DTI, and economic conditions drive default rates.
--      One row per state for clean star schema joins.

with geo_state as (
    select distinct
        addr_state,
        us_region
    from {{ ref('stg_loans') }}
    where addr_state is not null
)

select
    addr_state                                              as state_code,
    us_region,

    -- state population tier (helps BI users understand market size)
    case
        when addr_state in ('CA','TX','FL','NY','PA','IL','OH','GA','NC','MI') then 'Top 10 Population'
        when addr_state in ('NJ','VA','WA','AZ','MA','TN','IN','MO','MD','WI') then 'Mid-High Population'
        else 'Smaller Market'
    end as market_size_tier,

    -- regulatory environment classification
    case
        when addr_state in ('CA','NY','MA','CT','NJ','IL') then 'High Regulation'
        when addr_state in ('TX','FL','GA','AZ','NC','TN') then 'Moderate Regulation'
        else 'Standard Regulation'
    end as regulatory_environment,

    -- cost of living proxy (impacts ability to repay)
    case
        when addr_state in ('CA','NY','MA','HI','DC','CT','NJ','MD','WA') then 'High Cost'
        when addr_state in ('MS','AR','WV','AL','KY','OK','IN','IA','KS') then 'Low Cost'
        else 'Medium Cost'
    end as cost_of_living_tier,

    -- geographic risk zone (based on historical lending patterns)
    case
        when us_region = 'South'     then 'Higher Risk Zone'
        when us_region = 'Midwest'   then 'Moderate Risk Zone'
        when us_region = 'Northeast' then 'Lower Risk Zone'
        when us_region = 'West'      then 'Mixed Risk Zone'
        else 'Unknown'
    end as geographic_risk_zone

from geo_state
