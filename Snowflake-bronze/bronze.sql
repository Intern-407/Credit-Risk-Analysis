USE DATABASE LENDING_CLUB;
USE SCHEMA RAW;

CREATE OR REPLACE TRANSIENT TABLE LOANS_RAW (
  id STRING,
  member_id STRING,
  loan_amnt STRING,
  funded_amnt STRING,
  funded_amnt_inv STRING,
  term STRING,
  int_rate STRING,
  installment STRING,
  grade STRING,
  sub_grade STRING,
  emp_title STRING,
  emp_length STRING,
  home_ownership STRING,
  annual_inc STRING,
  verification_status STRING,
  issue_d STRING,
  loan_status STRING,
  pymnt_plan STRING,
  url STRING,
  "desc" STRING,
  purpose STRING,
  title STRING,
  zip_code STRING,
  addr_state STRING,
  dti STRING,
  delinq_2yrs STRING,
  earliest_cr_line STRING,
  fico_range_low STRING,
  fico_range_high STRING,
  inq_last_6mths STRING,
  mths_since_last_delinq STRING,
  mths_since_last_record STRING,
  open_acc STRING,
  pub_rec STRING,
  revol_bal STRING,
  revol_util STRING,
  total_acc STRING,
  initial_list_status STRING,
  out_prncp STRING,
  out_prncp_inv STRING,
  total_pymnt STRING,
  total_pymnt_inv STRING,
  total_rec_prncp STRING,
  total_rec_int STRING,
  total_rec_late_fee STRING,
  recoveries STRING,
  collection_recovery_fee STRING,
  last_pymnt_d STRING,
  last_pymnt_amnt STRING,
  next_pymnt_d STRING,
  last_credit_pull_d STRING,
  last_fico_range_high STRING,
  last_fico_range_low STRING,
  collections_12_mths_ex_med STRING,
  mths_since_last_major_derog STRING,
  policy_code STRING,
  application_type STRING,
  annual_inc_joint STRING,
  dti_joint STRING,
  verification_status_joint STRING,
  acc_now_delinq STRING,
  tot_coll_amt STRING,
  tot_cur_bal STRING,
  open_acc_6m STRING,
  open_act_il STRING,
  open_il_12m STRING,
  open_il_24m STRING,
  mths_since_rcnt_il STRING,
  total_bal_il STRING,
  il_util STRING,
  open_rv_12m STRING,
  open_rv_24m STRING,
  max_bal_bc STRING,
  all_util STRING,
  total_rev_hi_lim STRING,
  inq_fi STRING,
  total_cu_tl STRING,
  inq_last_12m STRING,
  acc_open_past_24mths STRING,
  avg_cur_bal STRING,
  bc_open_to_buy STRING,
  bc_util STRING,
  chargeoff_within_12_mths STRING,
  delinq_amnt STRING,
  mo_sin_old_il_acct STRING,
  mo_sin_old_rev_tl_op STRING,
  mo_sin_rcnt_rev_tl_op STRING,
  mo_sin_rcnt_tl STRING,
  mort_acc STRING,
  mths_since_recent_bc STRING,
  mths_since_recent_bc_dlq STRING,
  mths_since_recent_inq STRING,
  mths_since_recent_revol_delinq STRING,
  num_accts_ever_120_pd STRING,
  num_actv_bc_tl STRING,
  num_actv_rev_tl STRING,
  num_bc_sats STRING,
  num_bc_tl STRING,
  num_il_tl STRING,
  num_op_rev_tl STRING,
  num_rev_accts STRING,
  num_rev_tl_bal_gt_0 STRING,
  num_sats STRING,
  num_tl_120dpd_2m STRING,
  num_tl_30dpd STRING,
  num_tl_90g_dpd_24m STRING,
  num_tl_op_past_12m STRING,
  pct_tl_nvr_dlq STRING,
  percent_bc_gt_75 STRING,
  pub_rec_bankruptcies STRING,
  tax_liens STRING,
  tot_hi_cred_lim STRING,
  total_bal_ex_mort STRING,
  total_bc_limit STRING,
  total_il_high_credit_limit STRING,
  revol_bal_joint STRING,
  sec_app_fico_range_low STRING,
  sec_app_fico_range_high STRING,
  sec_app_earliest_cr_line STRING,
  sec_app_inq_last_6mths STRING,
  sec_app_mort_acc STRING,
  sec_app_open_acc STRING,
  sec_app_revol_util STRING,
  sec_app_open_act_il STRING,
  sec_app_num_rev_accts STRING,
  sec_app_chargeoff_within_12_mths STRING,
  sec_app_collections_12_mths_ex_med STRING,
  sec_app_mths_since_last_major_derog STRING,
  hardship_flag STRING,
  hardship_type STRING,
  hardship_reason STRING,
  hardship_status STRING,
  deferral_term STRING,
  hardship_amount STRING,
  hardship_start_date STRING,
  hardship_end_date STRING,
  payment_plan_start_date STRING,
  hardship_length STRING,
  hardship_dpd STRING,
  hardship_loan_status STRING,
  orig_projected_additional_accrued_interest STRING,
  hardship_payoff_balance_amount STRING,
  hardship_last_payment_amount STRING,
  disbursement_method STRING,
  debt_settlement_flag STRING,
  debt_settlement_flag_date STRING,
  settlement_status STRING,
  settlement_date STRING,
  settlement_amount STRING,
  settlement_percentage STRING,
  settlement_term STRING,
  _source_file STRING,
  _loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
CREATE SCHEMA IF NOT EXISTS LENDING_CLUB.AUDIT;

CREATE OR REPLACE TABLE LENDING_CLUB.AUDIT.PIPELINE_AUDIT_LOG (
  audit_id INT AUTOINCREMENT,
  layer STRING,              -- 'BRONZE', 'SILVER', 'GOLD'
  table_name STRING,
  source_file STRING,
  rows_loaded INT,
  rows_rejected INT,
  status STRING,              -- 'SUCCESS', 'PARTIAL', 'FAILED'
  started_at TIMESTAMP_NTZ,
  completed_at TIMESTAMP_NTZ,
  duration_seconds FLOAT
);

COPY INTO LOANS_RAW
(id, member_id, loan_amnt, funded_amnt, funded_amnt_inv, term, int_rate, installment, grade, sub_grade, emp_title, emp_length, home_ownership, annual_inc, verification_status, issue_d, loan_status, pymnt_plan, url, "desc", purpose, title, zip_code, addr_state, dti, delinq_2yrs, earliest_cr_line, fico_range_low, fico_range_high, inq_last_6mths, mths_since_last_delinq, mths_since_last_record, open_acc, pub_rec, revol_bal, revol_util, total_acc, initial_list_status, out_prncp, out_prncp_inv, total_pymnt, total_pymnt_inv, total_rec_prncp, total_rec_int, total_rec_late_fee, recoveries, collection_recovery_fee, last_pymnt_d, last_pymnt_amnt, next_pymnt_d, last_credit_pull_d, last_fico_range_high, last_fico_range_low, collections_12_mths_ex_med, mths_since_last_major_derog, policy_code, application_type, annual_inc_joint, dti_joint, verification_status_joint, acc_now_delinq, tot_coll_amt, tot_cur_bal, open_acc_6m, open_act_il, open_il_12m, open_il_24m, mths_since_rcnt_il, total_bal_il, il_util, open_rv_12m, open_rv_24m, max_bal_bc, all_util, total_rev_hi_lim, inq_fi, total_cu_tl, inq_last_12m, acc_open_past_24mths, avg_cur_bal, bc_open_to_buy, bc_util, chargeoff_within_12_mths, delinq_amnt, mo_sin_old_il_acct, mo_sin_old_rev_tl_op, mo_sin_rcnt_rev_tl_op, mo_sin_rcnt_tl, mort_acc, mths_since_recent_bc, mths_since_recent_bc_dlq, mths_since_recent_inq, mths_since_recent_revol_delinq, num_accts_ever_120_pd, num_actv_bc_tl, num_actv_rev_tl, num_bc_sats, num_bc_tl, num_il_tl, num_op_rev_tl, num_rev_accts, num_rev_tl_bal_gt_0, num_sats, num_tl_120dpd_2m, num_tl_30dpd, num_tl_90g_dpd_24m, num_tl_op_past_12m, pct_tl_nvr_dlq, percent_bc_gt_75, pub_rec_bankruptcies, tax_liens, tot_hi_cred_lim, total_bal_ex_mort, total_bc_limit, total_il_high_credit_limit, revol_bal_joint, sec_app_fico_range_low, sec_app_fico_range_high, sec_app_earliest_cr_line, sec_app_inq_last_6mths, sec_app_mort_acc, sec_app_open_acc, sec_app_revol_util, sec_app_open_act_il, sec_app_num_rev_accts, sec_app_chargeoff_within_12_mths, sec_app_collections_12_mths_ex_med, sec_app_mths_since_last_major_derog, hardship_flag, hardship_type, hardship_reason, hardship_status, deferral_term, hardship_amount, hardship_start_date, hardship_end_date, payment_plan_start_date, hardship_length, hardship_dpd, hardship_loan_status, orig_projected_additional_accrued_interest, hardship_payoff_balance_amount, hardship_last_payment_amount, disbursement_method, debt_settlement_flag, debt_settlement_flag_date, settlement_status, settlement_date, settlement_amount, settlement_percentage, settlement_term, _source_file)
FROM (
  SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,$43,$44,$45,$46,$47,$48,$49,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$80,$81,$82,$83,$84,$85,$86,$87,$88,$89,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$100,$101,$102,$103,$104,$105,$106,$107,$108,$109,$110,$111,$112,$113,$114,$115,$116,$117,$118,$119,$120,$121,$122,$123,$124,$125,$126,$127,$128,$129,$130,$131,$132,$133,$134,$135,$136,$137,$138,$139,$140,$141,$142,$143,$144,$145,$146,$147,$148,$149,$150,$151, METADATA$FILENAME
  FROM @BLOB_STAGE/landing/
)
ON_ERROR = 'CONTINUE';

INSERT INTO LENDING_CLUB.AUDIT.PIPELINE_AUDIT_LOG
  (layer, table_name, source_file, rows_loaded, rows_rejected, status, started_at, completed_at, duration_seconds)
SELECT
  'BRONZE',
  'LOANS_RAW',
  "file",
  "rows_loaded",
  "rows_parsed" - "rows_loaded",
  CASE WHEN "errors_seen" = 0 THEN 'SUCCESS' ELSE 'PARTIAL' END,
  CURRENT_TIMESTAMP(),
  CURRENT_TIMESTAMP(),
  NULL
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1)));

-- audit: what got loaded, per file
SELECT file_name, row_count, row_parsed, status, first_error_message, last_load_time
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'LENDING_CLUB.RAW.LOANS_RAW',
  START_TIME => DATEADD(hours, -1, CURRENT_TIMESTAMP())
));

-- test: total row count should be 2,260,668 (matches your split summary)
SELECT COUNT(*) AS total_rows FROM LOANS_RAW;

-- test: row count per source file should match your split job's row_counts
SELECT _source_file, COUNT(*) AS rows_loaded
FROM LOANS_RAW
GROUP BY _source_file
ORDER BY _source_file;



SELECT COUNT(*) AS BEFORE_ROW_COUNT
FROM LENDING_CLUB.RAW.LOANS_RAW;

SELECT COUNT(*) AS AFTER_ROW_COUNT
FROM LENDING_CLUB.RAW.LOANS_RAW;