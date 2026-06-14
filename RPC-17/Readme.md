# 📰 RPC_17 — Bharat Herald: Print-to-Digital Transition Analysis

> **An end-to-end Business Intelligence project** analyzing the operational health, advertising revenue, and digital readiness of *Bharat Herald*, a regional Hindi newspaper — built with MySQL, Power BI, and Python.

---

## 📌 Project Overview

Bharat Herald is a fictional regional newspaper operating across Tier 1, Tier 2, and Tier 3 cities in India. This project simulates a real-world BI engagement to help editorial and business leadership answer one central question:

> *Is Bharat Herald ready to transition from print to digital — and which cities should lead that shift?*

The analysis covers print circulation performance, advertising revenue trends, a short-lived digital pilot evaluation, and city-level digital readiness scoring.

---

## 🗂️ Repository Structure

```
RPC_17/
│
├── data/
│   ├── fact_print_sales.csv        # Monthly print performance by city
│   ├── fact_ad_revenue.csv         # Quarterly ad revenue by city & category
│   ├── fact_digital_pilot.csv      # Digital pilot (2021) platform metrics
│   ├── fact_city_readiness.csv     # Monthly digital readiness scores per city
│   ├── dim_city.xlsx               # City dimension (ID, state, tier)
│   └── dim_ad_category.xlsx        # Ad category dimension (normalized labels)
│
├── sql/
│   └── RPC_17.sql                  # All DDL, DML, and analytical queries
│
├── reports/
│   └── RPC_17.pbix                 # Power BI dashboard
│
├── docs/
│   └── Code_Basis_RPC_17_Project_Documentation.docx
│
└── README.md
```

---

## 🗄️ Data Model

The project uses a **Star Schema** with two dimension tables and four fact tables.

```
                    ┌─────────────┐
                    │  dim_city   │
                    │─────────────│
                    │ city_id (PK)│
                    │ city        │
                    │ state       │
                    │ tier        │
                    └──────┬──────┘
                           │
          ┌────────────────┼────────────────┐
          │                │                │
┌─────────▼──────┐ ┌───────▼────────┐ ┌────▼───────────────┐
│ fact_print_    │ │ fact_city_     │ │ fact_digital_pilot │
│ sales          │ │ readiness      │ │────────────────────│
│────────────────│ │────────────────│ │ platform           │
│ city_id (FK)   │ │ city_id (FK)   │ │ launch_month       │
│ month          │ │ month          │ │ dev_cost           │
│ copies_printed │ │ literacy_rate  │ │ marketing_cost     │
│ copies_sold    │ │ smartphone_pct │ │ users_reached      │
│ net_circulation│ │ internet_pct   │ │ downloads          │
└────────────────┘ └────────────────┘ │ avg_bounce_rate    │
                                       └────────────────────┘

┌──────────────────┐        ┌──────────────────────┐
│  fact_ad_revenue │        │   dim_ad_category    │
│──────────────────│        │──────────────────────│
│ edition          │───────▶│ raw_ad_category      │
│ quarter          │        │ standard_ad_category │
│ ad_category (FK) │        │ category_group       │
│ ad_revenue_in_inr│        │ example_brands       │
└──────────────────┘        └──────────────────────┘
```

---

## 📊 Tables Reference

### `fact_print_sales`
Monthly print performance across all city editions.

| Column | Type | Description |
|--------|------|-------------|
| city | VARCHAR | Edition/city name |
| month | VARCHAR | Month (YYYY-MM) |
| copies_printed | INT | Total copies printed |
| copies_sold | INT | Copies sold via kiosks/vendors |
| net_circulation | INT | Copies circulated after returns |

---

### `fact_ad_revenue`
Quarterly advertising revenue by city edition and category.

| Column | Type | Description |
|--------|------|-------------|
| edition | VARCHAR | City/region edition |
| quarter | VARCHAR | Quarter (e.g., 2022-Q1) |
| ad_category | VARCHAR | FK to `dim_ad_category` |
| currency | VARCHAR | Currency label (needs normalization) |
| ad_revenue_in_inr | DECIMAL | Revenue standardized in INR |

---

### `fact_digital_pilot`
Metrics from Bharat Herald's 2021 digital pilot programs.

| Column | Type | Description |
|--------|------|-------------|
| platform | VARCHAR | Platform type (e.g., Mobile App Beta, WhatsApp PDF) |
| launch_month | VARCHAR | Launch date (e.g., Mar-2021) |
| dev_cost | DECIMAL | Development cost (INR) |
| marketing_cost | DECIMAL | Promotion budget (INR) |
| users_reached | INT | Users targeted |
| downloads_or_accesses | INT | Users who actually accessed |
| avg_bounce_rate | FLOAT | % who quickly exited |
| cumulative_feedback | TEXT | Aggregated qualitative feedback |

---

### `fact_city_readiness`
Monthly digital readiness indicators per city — used to model digital adoption potential.

| Column | Type | Description |
|--------|------|-------------|
| city_id | VARCHAR | FK to `dim_city` |
| month | VARCHAR | Month (YYYY-MM) |
| literacy_rate | FLOAT | % literate population |
| smartphone_penetration | FLOAT | % with smartphone access |
| internet_penetration | FLOAT | % with internet access |

---

### `dim_city`
Master city lookup table.

| Column | Type | Description |
|--------|------|-------------|
| city_id | VARCHAR(10) PK | Unique city identifier |
| city | VARCHAR | City name |
| state | VARCHAR | State name |
| tier | VARCHAR | Tier classification (Tier 1 / 2 / 3) |

Cities covered: **Lucknow, Delhi, Bhopal, Patna, Jaipur, Mumbai, Ranchi, Kanpur, Ahmedabad, Varanasi**

---

### `dim_ad_category`
Normalized advertising category lookup with sector grouping.

| Column | Type | Description |
|--------|------|-------------|
| raw_ad_category | VARCHAR | Raw input label from source data |
| standard_ad_category | VARCHAR | Cleaned, standardized category |
| category_group | VARCHAR | Broad sector (e.g., Public Sector, Commercial Brands) |
| example_brands | VARCHAR | Sample advertisers (e.g., LIC, HUL, DLF) |

---

## 🔑 Business Questions Answered

### Q1 — Steepest Month-on-Month Circulation Decline
> *Which city-month combinations show the worst MoM drop in net circulation?*

Uses `LAG()` window function partitioned by city to compute month-over-month changes, then surfaces the **3 worst-performing** city-month pairs.

```sql
WITH circulation_change AS (
    SELECT city_id, c.city AS city_name, Month, Net_Circulation,
           Net_Circulation - LAG(Net_Circulation)
               OVER (PARTITION BY city_id ORDER BY Month) AS mom_change
    FROM sales s JOIN city c ON s.city_id = c.city_id
)
SELECT city_name, Month, mom_change
FROM circulation_change
WHERE mom_change < 0
ORDER BY mom_change ASC
LIMIT 3;
```

---

### Q2 — Ad Revenue Category Share by Year
> *What percentage of annual ad revenue does each category contribute — and how has it shifted year over year?*

Uses nested CTEs with `SUM() OVER()` for category and year totals, then `LAG()` to show prior-year comparisons alongside percentage contribution.

```sql
WITH cte AS (
    SELECT REGEXP_SUBSTR(quarter, '[0-9]{4}') AS Year, ad_category,
           SUM(ad_revenue) OVER (PARTITION BY REGEXP_SUBSTR(quarter,'[0-9]{4}'), ad_category) AS Category_Revenue,
           SUM(ad_revenue) OVER (PARTITION BY REGEXP_SUBSTR(quarter,'[0-9]{4}')) AS Year_Revenue
    FROM ad_revenue
)
SELECT Year, Category, ROUND(Category_Revenue/Year_Revenue*100, 1) AS pct_of_year_total ...
```

---

### Q3 — Circulation Efficiency by City (2024)
> *Which cities are most efficient at converting printed copies into circulated copies?*

Computes a **circulation efficiency ratio** (`net_circulation / copies_sold`) for each city across 2024 and ranks them using `ROW_NUMBER()`.

---

### Q5 — Year-over-Year Net Circulation Trend by City
> *How has each city's annual net circulation changed compared to the prior year?*

Aggregates yearly circulation per city using `SUM() + RIGHT(month, 2)` grouping, then applies `LAG()` over city-year ordering to compute absolute YoY change.

---

### Q6 — City Digital Readiness Ranking (2021)
> *Which cities were best positioned for digital adoption at the time of the pilot launch?*

Averages three readiness dimensions (literacy, smartphone penetration, internet penetration) per city for 2021, then ranks cities descending by composite readiness score.

```sql
WITH B6 AS (
    SELECT City,
           AVG((COALESCE(literacy_rate,0) + COALESCE(smartphone_penetration,0)
                + COALESCE(internet_penetration,0))) / 3 AS Readiness
    FROM City c LEFT JOIN City_Readiness r ON c.city_id = r.city_id
    WHERE LEFT(Quarter, 4) = 2021
    GROUP BY City
)
SELECT City, Readiness, ROW_NUMBER() OVER (ORDER BY Readiness DESC) AS readiness_rank
FROM B6;
```

---

## 📊 Power BI Report (`RPC_17.pbix`)

Data was connected to Power BI via the **MySQL Connector** and a full data model was built inside Power BI Desktop before creating two dashboards.

---

### 🔗 Power BI Data Model

The Power BI model mirrors the SQL star schema with additional tables to support time intelligence and field parameters.

| Table | Type | Role |
|-------|------|------|
| `Sales` | Fact | Print sales & circulation data |
| `Ad_Revenue` | Fact | Quarterly ad revenue by category |
| `City-Readiness` | Fact | Monthly readiness scores per city |
| `Pilot` | Fact | Digital pilot (2021) platform metrics |
| `City` | Dimension | City master (ID, state, tier) |
| `Ad_Category` | Dimension | Normalized ad category lookup |
| `DimDate` | Date Table | Enables time intelligence (YoY, MoM) |
| `Bridge Region` | Bridge Table | Handles many-to-many city relationships |
| `Measures (2)` | Measures Table | Centralized DAX measure repository |

---

### 📐 DAX Measures

Key measures built and used across both dashboards:

| Measure | Description |
|---------|-------------|
| `Total Revenue` | Total ad revenue in INR across selected filters |
| `Total Cost` | Combined development + marketing cost (digital pilot) |
| `Net Circulation` | Sum of net copies circulated |
| `Total City` | Count of distinct cities in context |
| `Gap Between Sold and Net Circulation` | Difference between copies sold and actual net circulation — highlights wastage/returns |
| `Y-Axis Parameter` | Field parameter enabling dynamic Y-axis switching in charts |
| `Parameter` | Field parameter for slicer-driven axis control |

---

### 🖥️ Dashboard Pages

#### Page 1 — Main Page
An executive overview combining print and revenue performance.

| Visual | Type | Fields Used |
|--------|------|-------------|
| KPI Cards | Card Visual | Total Cost · Total City · Total Revenue · Net Circulation |
| Revenue by Year & Category | Clustered Column Chart | Year · Ad Category · Total Revenue |
| Revenue vs Circulation by City | Scatter Chart | Net Circulation (X) · Total Revenue (Y) · City (Legend) |
| City Comparison Scatter | Scatter Chart | City-level distribution |
| Title / Description | Text Box | Static narrative text |

**Purpose:** Gives leadership a single-screen view of how print health and ad revenue relate across cities and time.

---

#### Page 2 — Copies Sold Analysis
A deep-dive into the gap between sold copies and net circulation, with dynamic filtering.

| Visual | Type | Fields Used |
|--------|------|-------------|
| Gap by City | Clustered Column Chart | City · Gap Between Sold and Net Circulation |
| Gap by Year | Clustered Column Chart | Year · Gap Between Sold and Net Circulation |
| Gap by City (filtered) | Clustered Column Chart | City · Gap Between Sold and Net Circulation |
| Y-Axis Slicer | Slicer | Y-Axis Parameter (dynamic axis switching) |
| City/Filter Slicer | Slicer | Parameter (field parameter slicer) |
| Title / Description | Text Box | Static narrative text |

**Purpose:** Helps operations teams identify which cities and years have the largest gap between sold copies and actual circulation — a key indicator of distribution inefficiency or returns.

---

### ⚙️ Power BI Setup

1. Open `reports/RPC_17.pbix` in **Power BI Desktop**
2. Go to **Home → Transform Data → Data Source Settings**
3. Update the MySQL server connection to your local instance (`localhost`, database: `codebasis`)
4. Enter your MySQL credentials when prompted
5. Click **Refresh** — all 9 tables will reload from your local database

---

## 🛠️ Tech Stack

| Layer | Tool |
|-------|------|
| Database | MySQL 8.0 |
| Analytical Queries | SQL (Window Functions, CTEs, Regex) |
| BI & Visualization | Power BI (DAX, Power Query) |

---

## ⚙️ Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/your-username/RPC_17.git
cd RPC_17
```

### 2. Create the database
```sql
CREATE DATABASE codebasis;
USE codebasis;
```

### 3. Import data
Load the CSV/XLSX files into your MySQL instance using MySQL Workbench's Table Data Import Wizard, or via CLI:
```bash
mysqlimport --local --fields-terminated-by=',' codebasis data/fact_print_sales.csv
```

### 4. Run the schema script
```bash
mysql -u root -p codebasis < sql/RPC_17.sql
```

### 5. Open the Power BI report
Open `reports/RPC_17.pbix` in Power BI Desktop. Update the data source connection string to point to your MySQL instance.

---

## 📈 Key SQL Concepts Used

- **Window Functions** — `LAG()`, `ROW_NUMBER()`, `SUM() OVER()`
- **CTEs** — Multi-level `WITH` clauses for readable, layered logic
- **Regex in SQL** — `REGEXP_SUBSTR()` for extracting year from quarter strings
- **COALESCE** — Null-safe aggregation for readiness scoring
- **Foreign Key Constraints** — Enforcing referential integrity across fact and dimension tables
- **Indexes** — Optimizing joins on `city_id` and `ad_category`

---

## 🧹 Data Quality Notes

| Issue | Resolution |
|-------|------------|
| BOM encoding in column name (`ï»¿edition_ID`) | Fixed with `ALTER TABLE ... CHANGE` |
| Inconsistent quarter formats (`2022-Q1` vs `Q4-2023`) | Extracted year using `REGEXP_SUBSTR()` |
| Mixed city name casing (`lucknow` vs `LUCKNOW`) | Normalized with `UPPER()` in queries |
| Null readiness values | Handled with `COALESCE(..., 0)` |
| Unknown extra columns in raw imports | Dropped via `ALTER TABLE ... DROP COLUMN` |

---

## 👤 Author

**Raj Kishore Agrawal**
Data Analyst | SQL · Power BI · Python

---

## 📄 License

This project is for portfolio and educational purposes. Data is synthetic and does not represent any real organization.
