# Telecom Customer Churn & Revenue Analysis

End-to-end BI project on 7,043 telecom customers: raw CSV → normalized SQL Server database (ETL stored procedure) → interactive 2-page Power BI dashboard.

## Business Problem

A telecom operator is losing roughly 1 in 4 customers. Leadership wants to know **who is leaving, why the risk is concentrated where it is, and how much monthly revenue is at stake**, so retention budget can be spent where it matters most.

## Tools

- **SQL Server (SSMS):** staging table, normalized schema, ETL stored procedure, analysis queries
- **Power BI:** data model (star schema), DAX measures, dashboard
- **DAX:** `CALCULATE`, `DIVIDE`, `SWITCH` (tenure segments), calculated columns
- **Dataset:** IBM Telco Customer Churn (public sample dataset, available on Kaggle)

## Approach

1. **Staging:** imported the flat CSV into SQL Server as a staging table (`Telco_Customer_Churn`).
2. **Normalization:** split the flat file into 4 tables (`Customers`, `Services`, `Billing`, `ChurnStatus`) linked by `customerID` with primary and foreign keys.
3. **ETL stored procedure (`usp_Load_TelecomChurn`):** clears child tables first and parent last, reloads parent first and children after, all inside a `TRY / CATCH` transaction with `ROLLBACK`, so a failed run never leaves half-loaded data. Safe to re-run (idempotent), row counts verified at 7,043 in every table.
4. **SQL analysis:** churn rate, revenue at risk (JOIN), churn by contract (GROUP BY), ARPU, and top 5 customers per contract (CTE + `ROW_NUMBER`).
5. **Power BI:** imported the 4 normalized tables, built relationships around `Customers`, wrote DAX measures that recalculate with every slicer, and added a tenure segmentation (New / Mid / Established / Loyal) with a custom sort order.

## Dashboard

**Page 1 – Executive Summary:** KPIs, churn rate by contract, churned vs retained, churned customers by payment method and internet service.

**Page 2 – Churn Deep-Dive:** churn by tenure segment, revenue at risk by tenure, churn by dependents, top 10 high-value retained customers, with Contract and Internet Service slicers synced across pages.

![Executive Summary](screenshots/page1_executive_summary.png)
![Churn Deep-Dive](screenshots/page2_deep_dive.png)

## Key Insights

1. **Contract type is the strongest churn signal.** Month-to-month customers churn at 42.71%, against 11.27% for one-year and 2.83% for two-year contracts. *Recommendation:* offer month-to-month users a discount to move to an annual plan.
2. **The first 12 months are the danger zone.** New customers churn at about 47%, falling steadily to about 10% for loyal (49+ months) customers. *Recommendation:* invest in onboarding and early-life retention rather than late-stage win-backs.
3. **Revenue at risk is large and early-weighted.** Churned customers represent roughly 139K in monthly charges (about 30% of the 456K total monthly revenue), and the New segment alone accounts for roughly half of it.
4. **Fiber optic and electronic check dominate the churned base.** Fiber optic users make up about 69% of churned customers (1,297 of 1,869) and electronic check payers about 57% (1,071 of 1,869). *Recommendation:* review Fiber pricing and service quality, and nudge electronic check users toward automatic payment methods.
5. **Household context matters.** Customers without dependents churn at roughly 31%, about double the rate of those with dependents (roughly 15%). *Recommendation:* target family or bundle plans at single-person households.

## Repository Structure

```
├── README.md
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_etl_procedure.sql
│   └── 03_analysis_queries.sql
├── powerbi/
│   └── Telecom_Churn_Dashboard.pbix
└── screenshots/
```

## How to Run

1. Download the IBM Telco Customer Churn CSV from Kaggle and import it into SQL Server as `Telco_Customer_Churn`.
2. Run `01_create_tables.sql`, then `02_etl_procedure.sql`, then `EXEC usp_Load_TelecomChurn;`.
3. Open `Telecom_Churn_Dashboard.pbix` in Power BI Desktop, update the data source to your server name, and refresh.

## What I Learned

Debugged real issues along the way (column truncation on load, bit-to-boolean type handling between SQL Server and Power BI, integer division in SQL, filter context in DAX), and learned why ETL should be transactional and re-runnable.

## Author

**Sanni** – BI / Data Analyst
[LinkedIn link here]
