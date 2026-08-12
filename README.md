# Credit Risk & Loan Portfolio Analytics (LendingClub)

End-to-end credit risk data pipeline built on a Medallion architecture (Bronze -> Silver -> Gold), running entirely in Snowflake, with Azure Blob Storage as the raw landing zone and dbt for all Silver and Gold transformations.

## Architecture

- **Data source:** CSV files, including incremental (updated) file drops, not just a one-time full load.
- **Landing zone:** Azure Blob Storage holds the raw LendingClub CSV files.
- **Bronze:** Raw files are loaded as-is into Snowflake (`LOANS_RAW`) via `COPY INTO`, with every column typed as text so a bad source value never breaks the load.
- **Silver:** A single dbt model, `int_loans_cleaned`, cleans, standardizes, de-duplicates, enriches, and validates the data. `stg_loans` and `stg_loans_rejected` both select from this one model, so all cleaning and data-quality logic lives in exactly one place.
- **Gold:** A dimensional star schema with one fact table (`fct_loans`) and eight dimension tables, plus two pre-aggregated marts for the heaviest dashboard views.
- **Visualization:** Streamlit in Snowflake, reading directly from the Gold layer.
- **Orchestration:** Dagster oversees the full flow end to end - from picking up new/incremental files in Azure Blob, through the Bronze/Silver/Gold load in Snowflake, to refreshing the Streamlit dashboard.

## Repository Contents

```
lendingclub_dbt/
  analyses/
  macros/
    generate_schema_name.sql
    log_layer_audit.sql
  models/
    staging/
      stg_loans.sql
      stg_loans_rejected.sql
      int_loans_cleaned.sql
      _staging__sources.yml
      _staging__models.yml
    marts/
      dimensions/
        dim_date.sql
        dim_borrower.sql
        dim_geography.sql
        dim_purpose.sql
        dim_loan_status.sql
        dim_credit_profile.sql
        dim_loan_terms.sql
        dim_vintage.sql
      fct_loans.sql
      _marts__models.yml
  seeds/
  snapshots/
  dbt_project.yml
  profiles.yml
  packages.yml
.gitignore
README.md
```

## Gold Layer — Star Schema

| Dimension | Business Question It Answers |
|---|---|
| `dim_date` | Seasonality, trend, and year-over-year comparison |
| `dim_borrower` | Who tends to default, based on socioeconomic profile |
| `dim_geography` | Whether regional regulation or market maturity affects risk |
| `dim_purpose` | Whether stated loan purpose predicts repayment behavior |
| `dim_loan_status` | Where a loan sits in the delinquency-to-charge-off funnel |
| `dim_credit_profile` | Whether credit grade and FICO band predict real-world default |
| `dim_loan_terms` | Whether loan structure (term, rate, application type) predicts risk |
| `dim_vintage` | How loans in the same origination cohort perform as they season |

`fct_loans` carries the measures (loan amount, outstanding principal, recoveries, default flag, etc.) and foreign keys into each dimension above. It is built as an incremental dbt model, so re-runs only process newly loaded rows. Only rows that pass all Silver-layer data quality checks are propagated into Gold.

## Data Quality

The Silver model runs 14 explicit validation checks (loan status, FICO range, financials, loan amount, DTI, interest rate, revolving utilization, payment, credit history, revolving balance, credit accounts, loan date, state, and grade), rolled up into a single `is_dq_passed` flag plus a human-readable `dq_fail_reasons` array so a quarantined row is debuggable without re-deriving the logic.

## Tech Stack

- Snowflake (Bronze, Silver, Gold, dbt Projects on Snowflake)
- dbt (Silver and Gold transformations)
- Azure Blob Storage (raw landing zone)
- Dagster (orchestration)
- Streamlit in Snowflake (analytics dashboard)

## Status

- [x] Bronze ingestion (Azure Blob -> Snowflake)
- [x] Silver cleaning and validation (`int_loans_cleaned`)
- [x] Gold star schema (8 dimensions, 1 fact table, 2 marts)
- [ ] Dagster orchestration project
- [ ] Streamlit-in-Snowflake dashboard

## Team

Team 4 - Data Engineering Internship Project
