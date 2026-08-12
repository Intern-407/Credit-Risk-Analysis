from email import message

import snowflake.connector
from azure.storage.blob import BlobServiceClient
import os
from dotenv import load_dotenv
load_dotenv()
from dagster import (
    asset, AssetExecutionContext, MaterializeResult, MetadataValue,
    RetryPolicy, define_asset_job, ScheduleDefinition, Definitions,
    sensor, run_status_sensor, RunRequest, SkipReason,
    DefaultSensorStatus, DagsterRunStatus,
)
import requests
import smtplib
from email.message import EmailMessage
from email.mime.text import MIMEText
SNOWFLAKE_CONFIG = {
    "account": os.environ["SNOWFLAKE_ACCOUNT"],
    "user": os.environ["SNOWFLAKE_USER"],
    "password": os.environ["SNOWFLAKE_PASSWORD"],
    "warehouse": "WH_LENDING",
    "database": "LENDING_CLUB",
    "schema": "RAW",
    "role": "ACCOUNTADMIN",
}

AZURE_CONN_STR = os.environ["AZURE_CONN_STR"]

AZURE_CONTAINER = "lendingclub-raw"

RETRY = RetryPolicy(max_retries=2, delay=30)
SLACK_WEBHOOK_URL = os.environ.get("SLACK_WEBHOOK_URL", "")

def send_slack_alert(message: str):
    if not SLACK_WEBHOOK_URL:
        return  # alerts not configured -- don't block the pipeline over this
    try:
        requests.post(SLACK_WEBHOOK_URL, json={"text": message}, timeout=10)
    except Exception:
        pass
def send_email_alert(subject: str, message: str):
    try:
        msg = MIMEText(message)
        msg["Subject"] = subject
        msg["From"] = os.environ["SMTP_USER"]
        msg["To"] = os.environ["ALERT_EMAIL_TO"]

        with smtplib.SMTP(os.environ["SMTP_HOST"], int(os.environ["SMTP_PORT"])) as server:
            server.starttls()
            server.login(
                os.environ["SMTP_USER"],
                os.environ["SMTP_PASSWORD"]
            )
            server.send_message(msg)

        print("✅ Email alert sent successfully.")

    except Exception as e:
        print(f"❌ Email alert failed: {e}")
# def send_email_alert(subject: str, message: str):
#     smtp_host = os.environ.get("SMTP_HOST")
#     smtp_port = int(os.environ.get("SMTP_PORT", "587"))
#     smtp_user = os.environ.get("SMTP_USER")
#     smtp_password = os.environ.get("SMTP_PASSWORD")
#     alert_email_to = os.environ.get("ALERT_EMAIL_TO")

#     if not all([smtp_host, smtp_user, smtp_password, alert_email_to]):
#         return

#     try:
#         msg = EmailMessage()
#         msg["Subject"] = subject
#         msg["From"] = smtp_user
#         msg["To"] = alert_email_to
#         msg.set_content(message)

#         with smtplib.SMTP(smtp_host, smtp_port) as server:
#             server.starttls()
#             server.login(smtp_user, smtp_password)
#             server.send_message(msg)

#     except Exception as e:
#         print(f"EMAIL ERROR: {type(e).__name__}: {e}")
#     raise

 
def run_sql(sql: str):

    conn = snowflake.connector.connect(**SNOWFLAKE_CONFIG)

    cur = conn.cursor()

    try:

        cur.execute(sql)

        result = cur.fetchall()

        return result

    finally:

        cur.close()

        conn.close()
 
 
@asset(retry_policy=RETRY)
def bronze_load(context: AssetExecutionContext):

    """Loads any new files from Blob landing/ into LOANS_RAW. COPY INTO

    automatically skips files already loaded, so this is safe to re-run."""

    sql = """

    COPY INTO LENDING_CLUB.RAW.LOANS_RAW

    (id, member_id, loan_amnt, funded_amnt, funded_amnt_inv, term, int_rate, installment,

     grade, sub_grade, emp_title, emp_length, home_ownership, annual_inc, verification_status,

     issue_d, loan_status, pymnt_plan, url, "desc", purpose, title, zip_code, addr_state, dti,

     delinq_2yrs, earliest_cr_line, fico_range_low, fico_range_high, inq_last_6mths,

     mths_since_last_delinq, mths_since_last_record, open_acc, pub_rec, revol_bal, revol_util,

     total_acc, initial_list_status, out_prncp, out_prncp_inv, total_pymnt, total_pymnt_inv,

     total_rec_prncp, total_rec_int, total_rec_late_fee, recoveries, collection_recovery_fee,

     last_pymnt_d, last_pymnt_amnt, next_pymnt_d, last_credit_pull_d, last_fico_range_high,

     last_fico_range_low, collections_12_mths_ex_med, mths_since_last_major_derog, policy_code,

     application_type, annual_inc_joint, dti_joint, verification_status_joint, acc_now_delinq,

     tot_coll_amt, tot_cur_bal, open_acc_6m, open_act_il, open_il_12m, open_il_24m,

     mths_since_rcnt_il, total_bal_il, il_util, open_rv_12m, open_rv_24m, max_bal_bc, all_util,

     total_rev_hi_lim, inq_fi, total_cu_tl, inq_last_12m, acc_open_past_24mths, avg_cur_bal,

     bc_open_to_buy, bc_util, chargeoff_within_12_mths, delinq_amnt, mo_sin_old_il_acct,

     mo_sin_old_rev_tl_op, mo_sin_rcnt_rev_tl_op, mo_sin_rcnt_tl, mort_acc, mths_since_recent_bc,

     mths_since_recent_bc_dlq, mths_since_recent_inq, mths_since_recent_revol_delinq,

     num_accts_ever_120_pd, num_actv_bc_tl, num_actv_rev_tl, num_bc_sats, num_bc_tl, num_il_tl,

     num_op_rev_tl, num_rev_accts, num_rev_tl_bal_gt_0, num_sats, num_tl_120dpd_2m, num_tl_30dpd,

     num_tl_90g_dpd_24m, num_tl_op_past_12m, pct_tl_nvr_dlq, percent_bc_gt_75,

     pub_rec_bankruptcies, tax_liens, tot_hi_cred_lim, total_bal_ex_mort, total_bc_limit,

     total_il_high_credit_limit, revol_bal_joint, sec_app_fico_range_low, sec_app_fico_range_high,

     sec_app_earliest_cr_line, sec_app_inq_last_6mths, sec_app_mort_acc, sec_app_open_acc,

     sec_app_revol_util, sec_app_open_act_il, sec_app_num_rev_accts,

     sec_app_chargeoff_within_12_mths, sec_app_collections_12_mths_ex_med,

     sec_app_mths_since_last_major_derog, hardship_flag, hardship_type, hardship_reason,

     hardship_status, deferral_term, hardship_amount, hardship_start_date, hardship_end_date,

     payment_plan_start_date, hardship_length, hardship_dpd, hardship_loan_status,

     orig_projected_additional_accrued_interest, hardship_payoff_balance_amount,

     hardship_last_payment_amount, disbursement_method, debt_settlement_flag,

     debt_settlement_flag_date, settlement_status, settlement_date, settlement_amount,

     settlement_percentage, settlement_term, _source_file)

    FROM (

      SELECT $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,

             $23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$40,$41,$42,

             $43,$44,$45,$46,$47,$48,$49,$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$60,$61,$62,

             $63,$64,$65,$66,$67,$68,$69,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$80,$81,$82,

             $83,$84,$85,$86,$87,$88,$89,$90,$91,$92,$93,$94,$95,$96,$97,$98,$99,$100,$101,

             $102,$103,$104,$105,$106,$107,$108,$109,$110,$111,$112,$113,$114,$115,$116,$117,

             $118,$119,$120,$121,$122,$123,$124,$125,$126,$127,$128,$129,$130,$131,$132,$133,

             $134,$135,$136,$137,$138,$139,$140,$141,$142,$143,$144,$145,$146,$147,$148,$149,

             $150,$151, METADATA$FILENAME

      FROM @LENDING_CLUB.RAW.BLOB_STAGE/landing/

    )

    ON_ERROR = 'CONTINUE';

    """

    result = run_sql(sql)
    context.log.info(f"Bronze load result: {result}")
    return MaterializeResult(metadata={"copy_result": MetadataValue.text(str(result))})
 
 
@asset(deps=[bronze_load], retry_policy=RETRY)
def run_dbt_transformations(context: AssetExecutionContext):

    """Triggers the deployed dbt project object to rebuild Silver + Gold."""

    result = run_sql(

        "EXECUTE DBT PROJECT LENDING_CLUB.ANALYTICS.lendingclub_dbt_project "

        "ARGS = 'build'"

    )

    context.log.info(f"dbt build result: {result}")
    return MaterializeResult(metadata={"dbt_result": MetadataValue.text(str(result))})
 
 
pipeline_job = define_asset_job(

    name="lending_club_pipeline",

    selection=[bronze_load, run_dbt_transformations],

)
 
daily_schedule = ScheduleDefinition(

    job=pipeline_job,

    cron_schedule="0 6 * * *",   # 6 AM daily — adjust as needed for your demo

)
 
 
@sensor(

    job=pipeline_job,

    minimum_interval_seconds=30,

    default_status=DefaultSensorStatus.RUNNING,

)

def blob_landing_sensor(context):

    svc = BlobServiceClient.from_connection_string(AZURE_CONN_STR)
    container = svc.get_container_client(AZURE_CONTAINER)

    all_files = {
        blob.name
        for blob in container.list_blobs(name_starts_with="landing/")
    }

    # Find non-CSV files
    non_csv_files = {
        file for file in all_files
        if not file.lower().endswith(".csv")
    }

    if non_csv_files:
        message = (
            "❌ NON-CSV FILE DETECTED. "
            "Only CSV files are allowed in the landing folder. "
            f"Rejected file(s): {', '.join(sorted(non_csv_files))}"
        )

        context.log.error(message)
        send_slack_alert(message)

        send_email_alert(
        subject="⚠️ Non-CSV File Detected - Lending Club Pipeline",
        message=message
    )

        return SkipReason(message)

    current_files = all_files

    last_seen_raw = context.cursor or ""
    last_seen = set(last_seen_raw.split(",")) if last_seen_raw else set()

    new_files = current_files - last_seen

    if not new_files:
        return SkipReason("No new CSV files in landing/ since last check.")

    context.update_cursor(",".join(sorted(current_files)))

    return RunRequest(
        run_key=",".join(sorted(new_files)),
        run_config={},
        tags={"new_files": ",".join(sorted(new_files))},
    )
@run_status_sensor(
    run_status=DagsterRunStatus.FAILURE,
    monitored_jobs=[pipeline_job]
)
def pipeline_failure_alert(context):

    message = (
        f"Lending Club pipeline FAILED\n\n"
        f"Run ID: {context.dagster_run.run_id}\n"
        f"Check the Dagster UI for details."
    )

    send_slack_alert(message)

    send_email_alert(
        subject="🔴 Lending Club Pipeline FAILED",
        message=message
    )
 
 
defs = Definitions(

    assets=[bronze_load, run_dbt_transformations],

    jobs=[pipeline_job],

    schedules=[daily_schedule],

    sensors=[blob_landing_sensor, pipeline_failure_alert],
)


