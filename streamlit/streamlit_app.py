import streamlit as st
import altair as alt
import pandas as pd
from snowflake.snowpark.context import get_active_session
from datetime import date

st.set_page_config(page_title="Credit Risk & Loan Portfolio", layout="wide")

# --- Custom CSS for professional styling ---
st.markdown("""
<style>
    .stApp {
        background: linear-gradient(180deg, #F4F6FA 0%, #EAEDF3 100%);
    }
    .block-container {
        padding-top: 0.6rem;
        padding-bottom: 1rem;
        max-width: 1600px;
    }
    .kpi-card {
        background: #FFFFFF;
        border: none;
        border-radius: 4px;
        padding: 20px 22px;
        box-shadow: 0 2px 6px rgba(0,0,0,0.06);
        margin-bottom: 10px;
        min-height: 105px;
        height: 105px;
        border-left: 4px solid transparent;
        display: flex;
        flex-direction: column;
        justify-content: center;
        position: relative;
        overflow: hidden;
    }
    .kpi-card::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 0;
        width: 100%;
        height: 3px;
        background: inherit;
        opacity: 0.4;
    }
    .kpi-label {
        color: #605E5C;
        font-weight: 600;
        font-size: 11.5px;
        letter-spacing: 0.2px;
        margin-bottom: 6px;
    }
    .kpi-value {
        font-weight: 700;
        font-size: 24px;
        line-height: 1.1;
        color: #201F1E;
    }
    .kpi-delta {
        font-size: 12px;
        font-weight: 600;
        margin-top: 4px;
    }
    .section-header {
        color: #1B2A4A;
        border-left: 4px solid #C9A227;
        padding-left: 10px;
        margin-top: 8px;
        margin-bottom: 8px;
        font-weight: 700;
        font-size: 16px;
    }
    [data-testid="stDataFrame"] th,
    [data-testid="stDataFrame"] th div,
    [data-testid="stDataFrame"] th span,
    [data-testid="stDataFrame"] [role="columnheader"],
    [data-testid="stDataFrame"] [role="columnheader"] div,
    [data-testid="stDataFrame"] [role="columnheader"] span {
        font-weight: 700 !important;
    }
    [data-testid="stDataFrame"] td {
        text-align: left !important;
    }
    [data-testid="stDataFrame"] td div {
        text-align: left !important;
        justify-content: flex-start !important;
    }
</style>
""", unsafe_allow_html=True)

# --- Session & helpers ---
session = get_active_session()

@st.cache_data(ttl=300)
def run_query(sql: str):
    df = session.sql(sql).to_pandas()
    df.columns = [c if (' ' in c or '(' in c or '$' in c) else c.lower() for c in df.columns]
    return df

NAVY = "#1B2A4A"
GOLD_COLOR = "#C9A227"
RED = "#B0392A"
GREEN = "#2E7D32"
BLUE = "#1565C0"
PURPLE = "#6A1B9A"

def kpi_card(label, value, delta=None, accent=NAVY):
    delta_html = ""
    if delta:
        color = GREEN if "+" in str(delta) or "good" in str(delta).lower() else RED
        delta_html = f'<div class="kpi-delta" style="color:{color};">{delta}</div>'
    st.markdown(f"""
    <div class="kpi-card" style="border-left-color:{accent};">
        <div class="kpi-label">{label}</div>
        <div class="kpi-value" style="color:{accent};">{value}</div>
        {delta_html}
    </div>
    """, unsafe_allow_html=True)

def section_header(text):
    st.markdown(f'<div class="section-header">{text}</div>', unsafe_allow_html=True)

# --- Header Banner ---
st.markdown("""
<div style="
    background: linear-gradient(135deg, #1B2A4A 0%, #2E4053 100%);
    border-radius: 12px;
    padding: 14px 28px;
    margin-bottom: 12px;
    box-shadow: 0 4px 16px rgba(27,42,74,0.2);
    display: flex; justify-content: space-between; align-items: center;
">
    <div>
        <h1 style="color:#FFFFFF; margin-bottom:2px; font-size:22px; font-weight:800;">
            Credit Risk & Loan Portfolio Analytics
        </h1>
        <p style="color:#C9A227; font-size:13px; font-weight:600; margin:0;">
            LendingClub
        </p>
    </div>
    <div style="color:#FFFFFF; font-size:12px; text-align:right;">
        <div style="opacity:0.7;">Last Refreshed</div>
        <div style="font-weight:700;">""" + str(date.today()) + """</div>
    </div>
</div>
""", unsafe_allow_html=True)

# --- Global Filters ---
refresh_col1, refresh_col2, refresh_col3 = st.columns([4, 1, 1])
with refresh_col1:
    st.markdown('<div class="section-header">🎛️ Filters & Controls</div>', unsafe_allow_html=True)
with refresh_col2:
    if st.button("🔄 Refresh", use_container_width=True):
        st.cache_data.clear()
        st.rerun()
with refresh_col3:
    def reset_filters():
        filter_keys = ["filter_grade", "filter_segment", "filter_region", "filter_vintage",
                       "filter_purpose", "filter_status", "filter_term", "filter_rate"]
        for k in filter_keys:
            st.session_state[k] = []
        st.session_state["filter_date"] = max_date
    st.button("🔃 Reset", use_container_width=True, on_click=reset_filters)

date_range = run_query("SELECT MIN(date_key) AS min_dt, MAX(date_key) AS max_dt FROM LENDING_CLUB.GOLD.FCT_LOANS")
min_date = pd.to_datetime(date_range['min_dt'][0]).date()
max_date = max(pd.to_datetime(date_range['max_dt'][0]).date(), date.today())

# Row 1: Date + Credit Profile filters (3 cols)
f1, f2, f3 = st.columns(3)
with f1:
    date_filter = st.date_input("📅 Date", value=max_date, min_value=min_date, max_value=max_date, key="filter_date")
    start_date = min_date
    end_date = date_filter
with f2:
    grade_opts = run_query("SELECT DISTINCT grade FROM LENDING_CLUB.GOLD.DIM_CREDIT_PROFILE ORDER BY grade")
    sel_grades = st.multiselect("🏷️ Grade", grade_opts['grade'].tolist(), key="filter_grade")
with f3:
    risk_opts = run_query("SELECT DISTINCT risk_segment FROM LENDING_CLUB.GOLD.DIM_CREDIT_PROFILE ORDER BY risk_segment")
    sel_segments = st.multiselect("⚠️ Risk Segment", risk_opts['risk_segment'].tolist(), key="filter_segment")

# Row 2: Geography + Vintage + Purpose (3 cols)
f4, f5, f6 = st.columns(3)
with f4:
    region_opts = run_query("SELECT DISTINCT us_region FROM LENDING_CLUB.GOLD.DIM_GEOGRAPHY WHERE us_region IS NOT NULL ORDER BY us_region")
    sel_regions = st.multiselect("🌍 Region", region_opts['us_region'].tolist(), key="filter_region")
with f5:
    vintage_opts = run_query("SELECT DISTINCT vintage_year FROM LENDING_CLUB.GOLD.DIM_VINTAGE ORDER BY vintage_year")
    sel_years = st.multiselect("📈 Vintage Year", vintage_opts['vintage_year'].tolist(), key="filter_vintage")
with f6:
    purpose_opts = run_query("SELECT DISTINCT purpose_name FROM LENDING_CLUB.GOLD.DIM_PURPOSE ORDER BY purpose_name")
    sel_purposes = st.multiselect("🎯 Purpose", purpose_opts['purpose_name'].tolist(), key="filter_purpose")

# Row 3: Loan Status + Term + Rate Band (3 cols)
f7, f8, f9 = st.columns(3)
with f7:
    status_opts = run_query("SELECT DISTINCT status_name FROM LENDING_CLUB.GOLD.DIM_LOAN_STATUS ORDER BY status_name")
    sel_statuses = st.multiselect("📋 Loan Status", status_opts['status_name'].tolist(), key="filter_status")
with f8:
    term_opts = run_query("SELECT DISTINCT term_months FROM LENDING_CLUB.GOLD.DIM_LOAN_TERMS ORDER BY term_months")
    sel_terms = st.multiselect("⏱️ Term", term_opts['term_months'].tolist(), key="filter_term")
with f9:
    rate_opts = ['Low (<10%)', 'Medium (10-20%)', 'High (20%+)']
    sel_rates = st.multiselect("💰 Interest Rate Band", rate_opts, key="filter_rate")

st.markdown("---")

# --- Build dynamic WHERE clause ---
def build_where():
    clauses = [f"f.date_key >= '{start_date}'", f"f.date_key <= '{end_date}'"]
    if sel_grades:
        clauses.append(f"cp.grade IN ({','.join(repr(g) for g in sel_grades)})")
    if sel_segments:
        clauses.append(f"cp.risk_segment IN ({','.join(repr(s) for s in sel_segments)})")
    if sel_regions:
        clauses.append(f"g.us_region IN ({','.join(repr(r) for r in sel_regions)})")
    if sel_years:
        clauses.append(f"v.vintage_year IN ({','.join(str(y) for y in sel_years)})")
    if sel_purposes:
        clauses.append(f"p.purpose_name IN ({','.join(repr(p) for p in sel_purposes)})")
    if sel_statuses:
        clauses.append(f"ls.status_name IN ({','.join(repr(s) for s in sel_statuses)})")
    if sel_terms:
        clauses.append(f"lt.term_months IN ({','.join(repr(t) for t in sel_terms)})")
    if sel_rates:
        clauses.append(f"lt.int_rate_band IN ({','.join(repr(r) for r in sel_rates)})")
    return " AND ".join(clauses)

where = build_where()
base_from = """
    FROM LENDING_CLUB.GOLD.FCT_LOANS f
    JOIN LENDING_CLUB.GOLD.DIM_CREDIT_PROFILE cp ON f.credit_profile_key = cp.credit_profile_key
    JOIN LENDING_CLUB.GOLD.DIM_GEOGRAPHY g ON f.state_code = g.state_code
    JOIN LENDING_CLUB.GOLD.DIM_DATE d ON f.date_key = d.date_key
    JOIN LENDING_CLUB.GOLD.DIM_VINTAGE v ON f.vintage_date_key = v.vintage_date_key
    JOIN LENDING_CLUB.GOLD.DIM_PURPOSE p ON f.purpose_name = p.purpose_name
    JOIN LENDING_CLUB.GOLD.DIM_LOAN_STATUS ls ON f.status_name = ls.status_name
    JOIN LENDING_CLUB.GOLD.DIM_LOAN_TERMS lt ON f.loan_terms_key = lt.loan_terms_key
"""

# =============================================================================
# TABS
# =============================================================================
tab1, tab2, tab4 = st.tabs([
    "📊 Portfolio Overview", "🎯 Credit Risk Analysis",
    "📈 Vintage & Cohort"
])

# =============================================================================
# TAB 1: PORTFOLIO OVERVIEW   (unchanged)
# =============================================================================
with tab1:
    section_header("Portfolio KPIs")

    kpi_df = run_query(f"""
        SELECT COUNT(*) AS total_loans,
               SUM(f.funded_amnt) AS total_funded,
               ROUND(100.0 * SUM(f.is_default) / NULLIF(COUNT(*),0), 2) AS default_rate,
               ROUND(SUM(f.int_rate * f.funded_amnt) / NULLIF(SUM(f.funded_amnt),0), 2) AS wavg_rate,
               ROUND(AVG(f.fico_avg), 0) AS avg_fico,
               ROUND(AVG(f.dti), 2) AS avg_dti,
               SUM(f.outstanding_principal) AS outstanding,
               ROUND(AVG(f.loan_amnt), 0) AS avg_loan,
               SUM(f.total_pymnt) AS total_payments,
               SUM(f.net_loss_amount) AS total_loss
        {base_from}
        WHERE {where}
    """)

    k = kpi_df.iloc[0]
    c1, c2, c3, c4, c5 = st.columns(5)
    with c1:
        kpi_card("Total Loans", f"{int(k['total_loans']):,}", accent=NAVY)
    with c2:
        kpi_card("Total Funded", f"${k['total_funded']/1e6:,.0f}M", accent=NAVY)
    with c3:
        kpi_card("Default Rate", f"{k['default_rate']}%", accent=RED)
    with c4:
        kpi_card("Avg FICO", f"{int(k['avg_fico'])}", accent=GOLD_COLOR)
    with c5:
        kpi_card("Avg DTI", f"{k['avg_dti']}%", accent=BLUE)

    c6, c7, c8, c9, c10 = st.columns(5)
    with c6:
        kpi_card("Wt. Avg Rate", f"{k['wavg_rate']}%", accent=GOLD_COLOR)
    with c7:
        kpi_card("Avg Loan Size", f"${int(k['avg_loan']):,}", accent=BLUE)
    with c8:
        kpi_card("Outstanding", f"${k['outstanding']/1e6:,.0f}M", accent=NAVY)
    with c9:
        kpi_card("Total Payments", f"${k['total_payments']/1e6:,.0f}M", accent=GREEN)
    with c10:
        kpi_card("Net Losses", f"${abs(k['total_loss'])/1e6:,.0f}M", accent=RED)

    st.write("")
    chart_col1, chart_col2 = st.columns(2)

    with chart_col1:
        section_header("Loan Lifecycle Waterfall")

        funded_val = k['total_funded'] / 1e6
        payments_val = k['total_payments'] / 1e6
        outstanding_val = k['outstanding'] / 1e6
        loss_val = abs(k['total_loss']) / 1e6
        recovery_ratio = round(float(k['total_payments']) / max(float(k['total_funded']), 1) * 100, 1)

        waterfall_data = pd.DataFrame({
            'Stage': ['Total Funded', 'Total Payments', 'Outstanding', 'Net Losses'],
            'Amount ($M)': [funded_val, payments_val, outstanding_val, loss_val],
            'Status': ['Originated', 'Recovered', 'At Risk', 'Lost'],
            'Pct of Funded': [
                '100%',
                f'{recovery_ratio}%',
                f'{round(outstanding_val / max(funded_val, 1) * 100, 1)}%',
                f'{round(loss_val / max(funded_val, 1) * 100, 1)}%'
            ]
        })

        bars = alt.Chart(waterfall_data).mark_bar(
            cornerRadiusTopLeft=8, cornerRadiusTopRight=8, size=40
        ).encode(
            x=alt.X('Stage:N', title=None, sort=['Total Funded', 'Total Payments', 'Outstanding', 'Net Losses'],
                     axis=alt.Axis(labelFontSize=10, labelFontWeight='bold')),
            y=alt.Y('Amount ($M):Q', title='Amount ($M)', axis=alt.Axis(format='~s')),
            color=alt.Color('Status:N', scale=alt.Scale(
                domain=['Originated', 'Recovered', 'At Risk', 'Lost'],
                range=[NAVY, GREEN, GOLD_COLOR, RED]
            ), legend=alt.Legend(orient='top', title=None)),
            tooltip=['Stage', alt.Tooltip('Amount ($M):Q', format='$,.0f'), 'Pct of Funded']
        )

        text = alt.Chart(waterfall_data).mark_text(
            dy=-12, fontSize=11, fontWeight='bold', color='#1B2A4A'
        ).encode(
            x=alt.X('Stage:N', sort=['Total Funded', 'Total Payments', 'Outstanding', 'Net Losses']),
            y=alt.Y('Amount ($M):Q'),
            text=alt.Text('Pct of Funded:N')
        )

        chart = (bars + text).properties(height=320)
        st.altair_chart(chart, use_container_width=True)

    with chart_col2:
        section_header("Funded Volume Over Time")

        if 'drill_year' not in st.session_state:
            st.session_state.drill_year = None

        if st.session_state.drill_year is None:
            trend_df = run_query(f"""
                SELECT d.calendar_year AS period,
                       COUNT(*) AS loan_count,
                       SUM(f.funded_amnt) AS funded,
                       ROUND(100.0 * SUM(f.is_default) / COUNT(*), 2) AS default_rate
                {base_from}
                WHERE {where}
                GROUP BY d.calendar_year
                ORDER BY d.calendar_year
            """)
            if not trend_df.empty:
                chart_vol = alt.Chart(trend_df).mark_bar(
                    cornerRadiusTopLeft=6, cornerRadiusTopRight=6, color=NAVY
                ).encode(
                    x=alt.X('period:O', title='Year', axis=alt.Axis(labelAngle=0)),
                    y=alt.Y('funded:Q', title='Funded Amount ($)', axis=alt.Axis(format='~s')),
                    tooltip=['period', alt.Tooltip('funded:Q', format='$,.0f'), 'loan_count']
                ).properties(height=320)
                st.altair_chart(chart_vol, use_container_width=True)

                year_options = trend_df['period'].tolist()
                sel_year = st.selectbox("Select a year to drill into quarters", year_options,
                                       index=None, placeholder="Click to drill down...", key="year_pick")
                if sel_year:
                    st.session_state.drill_year = sel_year
                    st.rerun()
        else:
            selected_year = st.session_state.drill_year
            trend_df = run_query(f"""
                SELECT d.year_quarter_label AS period,
                       COUNT(*) AS loan_count,
                       SUM(f.funded_amnt) AS funded,
                       ROUND(100.0 * SUM(f.is_default) / COUNT(*), 2) AS default_rate
                {base_from}
                WHERE {where} AND d.calendar_year = {selected_year}
                GROUP BY d.year_quarter_label, d.calendar_quarter
                ORDER BY d.calendar_quarter
            """)
            if not trend_df.empty:
                chart_vol = alt.Chart(trend_df).mark_bar(
                    cornerRadiusTopLeft=6, cornerRadiusTopRight=6, color=NAVY
                ).encode(
                    x=alt.X('period:N', title='Quarter', sort=None, axis=alt.Axis(labelAngle=0)),
                    y=alt.Y('funded:Q', title='Funded Amount ($)', axis=alt.Axis(format='~s')),
                    tooltip=['period', alt.Tooltip('funded:Q', format='$,.0f'), 'loan_count']
                ).properties(height=320, title=f'Funded Volume — {selected_year} Quarters')
                st.altair_chart(chart_vol, use_container_width=True)

            if st.button("← Back to Years", key="back_to_years"):
                st.session_state.drill_year = None
                st.rerun()

    st.write("")
    section_header("Portfolio Analytics by Loan Status")

    status_table = run_query(f"""
        SELECT ls.status_name AS "Loan Status",
               ls.performance_category AS "Performance",
               COUNT(*) AS "Total Loans",
               ROUND(SUM(f.funded_amnt)/1e6, 1) AS "Funded ($M)",
               ROUND(AVG(f.int_rate), 2) AS "Avg Rate (%)",
               ROUND(AVG(f.fico_avg), 0) AS "Avg FICO",
               ROUND(SUM(f.outstanding_principal)/1e6, 1) AS "Outstanding ($M)",
               ROUND(SUM(f.net_loss_amount)/1e6, 1) AS "Net Loss ($M)"
        {base_from}
        WHERE {where}
        GROUP BY ls.status_name, ls.performance_category
        ORDER BY "Funded ($M)" DESC
    """)
    if not status_table.empty:
        st.dataframe(status_table, use_container_width=True, height=320, hide_index=True)
        st.download_button("📥 Download Status Analysis (CSV)", status_table.to_csv(index=False),
                         file_name="portfolio_status_analysis.csv", mime="text/csv", use_container_width=True,
                         key="download_status_top")

# =============================================================================
# TAB 2: CREDIT RISK ANALYSIS   (unchanged)
# =============================================================================
with tab2:
    section_header("Credit Risk Profile Cards")

    risk_cards = run_query(f"""
        SELECT cp.risk_segment, COUNT(*) AS loans,
               ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS default_rate,
               ROUND(AVG(f.fico_avg), 0) AS avg_fico,
               ROUND(AVG(f.int_rate), 2) AS avg_rate,
               ROUND(SUM(f.net_loss_amount)/1e6, 2) AS net_loss_m
        {base_from}
        WHERE {where}
        GROUP BY cp.risk_segment ORDER BY default_rate
    """)

    if not risk_cards.empty:
        cols = st.columns(len(risk_cards))
        colors = {'Prime': GREEN, 'Near-Prime': GOLD_COLOR, 'Subprime': '#FF8F00', 'Deep-Subprime': RED}
        for i, row in risk_cards.iterrows():
            with cols[i]:
                accent = colors.get(row['risk_segment'], NAVY)
                st.markdown(f"""
                <div class="kpi-card" style="border-top:4px solid {accent}; min-height:180px;">
                    <div class="kpi-label">{row['risk_segment']}</div>
                    <div class="kpi-value">{row['default_rate']}%</div>
                    <div style="font-size:11px; color:#6B7280; margin-top:6px;">
                        📊 {row['loans']/1e6:.2f}M loans<br/>
                        🎯 FICO: {int(row['avg_fico'])}<br/>
                        💰 Rate: {row['avg_rate']}%<br/>
                        📉 Loss: ${row['net_loss_m']}M
                    </div>
                </div>
                """, unsafe_allow_html=True)

    st.write("")
    # section_header("Default Rate By Risk Segment & FICO")

    col_risk1, col_risk2 = st.columns(2)
    with col_risk1:
        seg_risk_df = run_query(f"""
            SELECT cp.risk_segment, COUNT(*) AS loans,
                   ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS default_rate
            {base_from}
            WHERE {where}
            GROUP BY cp.risk_segment ORDER BY default_rate DESC
        """)
        chart = alt.Chart(seg_risk_df).mark_bar(cornerRadiusTopLeft=3, cornerRadiusTopRight=3).encode(
            x=alt.X('risk_segment:N', title='Risk Segment', sort='-y'),
            y=alt.Y('default_rate:Q', title='Default Rate (%)'),
            color=alt.Color('risk_segment:N', scale=alt.Scale(
                domain=['Prime','Near-Prime','Subprime','Deep-Subprime'],
                range=[GREEN, GOLD_COLOR, '#FF8F00', RED]
            ), legend=None),
            tooltip=['risk_segment', 'loans', alt.Tooltip('default_rate:Q', format='.2f')]
        ).properties(height=300, title='Default Rate By Risk Segment')
        st.altair_chart(chart, use_container_width=True)

    with col_risk2:
        fico_df = run_query(f"""
            SELECT FLOOR(f.fico_avg / 20) * 20 AS fico_band, COUNT(*) AS loans,
                   ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS default_rate
            {base_from}
            WHERE {where} AND f.fico_avg IS NOT NULL
            GROUP BY FLOOR(f.fico_avg / 20) * 20
            ORDER BY fico_band
        """)
        chart = alt.Chart(fico_df).mark_bar(
            cornerRadiusTopLeft=4, cornerRadiusTopRight=4
        ).encode(
            x=alt.X('fico_band:O', title='FICO Score Band'),
            y=alt.Y('loans:Q', title='Loan Count', axis=alt.Axis(format='~s')),
            color=alt.Color('default_rate:Q', scale=alt.Scale(
                scheme='redyellowgreen', reverse=True
            ), title='Default %'),
            tooltip=[alt.Tooltip('fico_band:O', title='FICO Band'),
                     alt.Tooltip('loans:Q', format=','),
                     alt.Tooltip('default_rate:Q', format='.2f', title='Default Rate %')]
        ).properties(height=300, title='Loan Distribution by FICO ')
        st.altair_chart(chart, use_container_width=True)

    st.write("")
    section_header("Geographic Risk Summary")

    geo_table = run_query(f"""
        SELECT g.us_region AS "Region",
               f.state_code AS "State",
               COUNT(*) AS "Loans",
               ROUND(SUM(f.funded_amnt)/1e6, 1) AS "Funded ($M)",
               ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS "Default Rate (%)",
               ROUND(AVG(f.fico_avg), 0) AS "Avg FICO",
               ROUND(AVG(f.int_rate), 2) AS "Avg Rate (%)",
               ROUND(SUM(f.net_loss_amount)/1e6, 2) AS "Net Loss ($M)"
        {base_from}
        WHERE {where}
        GROUP BY g.us_region, f.state_code
        HAVING COUNT(*) >= 100
        ORDER BY "Default Rate (%)" DESC
    """)
    if not geo_table.empty:
        st.dataframe(geo_table, use_container_width=True, height=400, hide_index=True)
        st.download_button("📥 Download Geographic Risk Data (CSV)", geo_table.to_csv(index=False),
                         file_name="geographic_risk_summary.csv", mime="text/csv", use_container_width=True,
                         key="download_geo_risk")


# =============================================================================
# TAB 4: VINTAGE & COHORT ANALYSIS   (unchanged)
# =============================================================================
with tab4:
    section_header("Vintage Era Performance Cards")

    era_cards = run_query(f"""
        SELECT v.vintage_era, COUNT(*) AS loans,
               ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS default_rate,
               ROUND(AVG(f.fico_avg), 0) AS avg_fico,
               ROUND(AVG(f.int_rate), 2) AS avg_rate
        {base_from}
        WHERE {where}
        GROUP BY v.vintage_era ORDER BY default_rate DESC
    """)

    if not era_cards.empty:
        cols = st.columns(min(len(era_cards), 5))
        era_colors = ['#B0392A', '#FF8F00', '#C9A227', '#1565C0', '#2E7D32']
        for i, row in era_cards.iterrows():
            if i < 5:
                with cols[i]:
                    st.markdown(f"""
                    <div class="kpi-card" style="border-top:4px solid {era_colors[i % 5]}; min-height:160px;">
                        <div class="kpi-label">{row['vintage_era']}</div>
                        <div class="kpi-value">{row['default_rate']}%</div>
                        <div style="font-size:11px; color:#6B7280; margin-top:6px;">
                            📊 {row['loans']/1e6:.2f}M loans<br/>
                            🎯 FICO: {int(row['avg_fico'])}<br/>
                            💰 Rate: {row['avg_rate']}%
                        </div>
                    </div>
                    """, unsafe_allow_html=True)

    st.write("")
    section_header("Vintage Curve — Funded Volume & Default Rate by Vintage Year ")

    vintage_trend = run_query(f"""
        SELECT v.vintage_year AS period,
               COUNT(*) AS loans,
               ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS default_rate,
               ROUND(AVG(f.int_rate), 2) AS avg_rate,
               ROUND(SUM(f.funded_amnt)/1e6, 1) AS funded_m
        {base_from}
        WHERE {where}
        GROUP BY v.vintage_year
        ORDER BY v.vintage_year
    """)

    if not vintage_trend.empty:
        bars = alt.Chart(vintage_trend).mark_bar(
            cornerRadiusTopLeft=6, cornerRadiusTopRight=6, opacity=0.7
        ).encode(
            x=alt.X('period:O', title='Vintage Year', axis=alt.Axis(labelAngle=0)),
            y=alt.Y('funded_m:Q', title='Funded ($M)', axis=alt.Axis(format='~s')),
            color=alt.Color('default_rate:Q', scale=alt.Scale(
                scheme='redyellowgreen', reverse=True
            ), title='Default %'),
            tooltip=['period', alt.Tooltip('funded_m:Q', format='$,.1f', title='Funded ($M)'),
                     alt.Tooltip('loans:Q', format=','),
                     alt.Tooltip('default_rate:Q', format='.2f', title='Default Rate %'),
                     alt.Tooltip('avg_rate:Q', format='.2f', title='Avg Int Rate %')]
        )

        line = alt.Chart(vintage_trend).mark_line(
            color=RED, strokeWidth=3, point=alt.OverlayMarkDef(filled=True, size=60, color=RED)
        ).encode(
            x=alt.X('period:O'),
            y=alt.Y('default_rate:Q', title='Default Rate (%)',
                     axis=alt.Axis(titleColor=RED)),
            tooltip=[alt.Tooltip('default_rate:Q', format='.2f', title='Default Rate %')]
        )

        chart = alt.layer(bars, line).resolve_scale(
            y='independent'
        ).properties(height=350)
        st.altair_chart(chart, use_container_width=True)

    st.write("")
    section_header("Borrower Risk Profile")

    borrower_table = run_query(f"""
        SELECT p.purpose_name AS "Loan Purpose",
               b.home_ownership AS "Home Ownership",
               COUNT(*) AS "Loans",
               ROUND(100.0 * SUM(f.is_default)/COUNT(*), 2) AS "Default Rate (%)",
               ROUND(AVG(f.fico_avg), 0) AS "Avg FICO",
               ROUND(AVG(f.annual_inc), 0) AS "Avg Income ($)"
        {base_from}
        JOIN LENDING_CLUB.GOLD.DIM_BORROWER b ON f.borrower_key = b.borrower_key
        WHERE {where}
        GROUP BY p.purpose_name, b.home_ownership
        HAVING COUNT(*) >= 100
        ORDER BY "Default Rate (%)" DESC
    """)
    if not borrower_table.empty:
        st.dataframe(borrower_table, use_container_width=True, height=400, hide_index=True)
        st.download_button("📥 Download Borrower Risk Data (CSV)", borrower_table.to_csv(index=False),
                         file_name="borrower_risk_profile.csv", mime="text/csv", use_container_width=True,
                         key="download_borrower_risk")
