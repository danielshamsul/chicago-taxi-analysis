# 🚕 Chicago Taxi Trips — Data Analytics Assessment
**Submitted by:** Muhammad Daniel Bin Shamsul Azlie
**Assessment:** Time DotCom Data Analytics Engineer

---

## 📌 Overview

This project is a production-ready data analytics pipeline built on Google Cloud Platform (GCP). It transforms the publicly available **Chicago Taxi Trips** dataset from BigQuery into meaningful analytical models using **dbt (Data Build Tool)**, visualised through a **Looker Studio** dashboard, and automated via a **CI/CD pipeline** using GitHub Actions.

> **Note:** This was my first experience working with dbt. I approached this assessment as a learning opportunity, applying my existing knowledge of GCP and CI/CD from my previous role at Maxis to complete the project end-to-end.

---

## 🏗️ Architecture

```
BigQuery Public Dataset
(bigquery-public-data.chicago_taxi_trips.taxi_trips)
            │
            ▼
      dbt Transformation
    ┌─────────────────────┐
    │  Staging Layer      │  ← stg_taxi_trips (data cleaning)
    └─────────────────────┘
            │
            ▼
    ┌─────────────────────┐
    │  Marts Layer        │  ← top_tip_earners
    │                     │  ← overworkers
    │                     │  ← holiday_impact
    └─────────────────────┘
            │
            ▼
    BigQuery Dataset: chicago_taxi_dbt
            │
            ▼
      Looker Studio Dashboard
```

---

## 🛠️ Core Technologies

| Tool | Purpose |
|---|---|
| **Google BigQuery** | Data warehouse |
| **dbt Core** | Data transformation |
| **Looker Studio** | Data visualisation |
| **GitHub Actions** | CI/CD pipeline |
| **Google Cloud Shell** | Development environment |
| **Workload Identity Federation** | Secure keyless GCP authentication |

---

## 📂 Project Structure

```
chicago_taxi_analysis/
├── models/
│   ├── staging/
│   │   └── stg_taxi_trips.sql        ← Cleans raw data
│   └── marts/
│       ├── top_tip_earners.sql       ← Top 100 tip earners
│       ├── overworkers.sql           ← Top 100 overworking drivers
│       └── holiday_impact.sql        ← Holiday vs normal day trips
├── .github/
│   └── workflows/
│       └── dbt_ci.yml                ← GitHub Actions CI/CD workflow
├── dbt_project.yml
└── README.md
```

---

## 📊 Dataset

- **Source:** Google BigQuery Public Data
- **Table:** `bigquery-public-data.chicago_taxi_trips.taxi_trips`
- **Coverage:** Taxi trips in Chicago from 2013 to present
- **Key Fields:** `taxi_id`, `trip_start_timestamp`, `trip_end_timestamp`, `trip_miles`, `fare`, `tips`, `trip_total`

> Taxi IDs are anonymised/encrypted to protect driver privacy in compliance with data protection regulations (similar to PDPA).

---

## 🔄 Data Models

### Staging — `stg_taxi_trips`
**Purpose:** Cleans and standardises the raw dataset before analysis.

**Transformations applied:**
- Removed rows with null timestamps
- Filtered out trips where end time is before start time
- Removed negative fare amounts
- Removed rows with no taxi ID
- Standardised timestamps to the nearest minute
- Calculated trip duration in minutes

---

### Mart 1 — `top_tip_earners`
**Business Question:** Who are the top 100 taxi drivers earning the most in tips over the last 90 days?

**Methodology:**
- Filtered trips to the last 90 days using the most recent available date in the dataset (rather than today's date, since the dataset ends around 2023)
- Grouped by `taxi_id` and aggregated total tips, average tip per trip, and total revenue
- Ranked by total tips descending, limited to top 100

**Assumptions:**
- "Last 90 days" is calculated from the maximum available date in the dataset, not the current date, to ensure results are always meaningful regardless of when the query runs

---

### Mart 2 — `overworkers`
**Business Question:** Who are the top 100 taxi drivers working the most hours without adequate rest?

**Methodology:**
- Used a SQL window function (`LAG`) to calculate the time gap between each driver's consecutive trips
- Flagged trips where the break between the previous trip ending and the next trip starting was less than 8 hours (480 minutes)
- Counted how many times each driver had a short break and calculated their average break duration
- Ranked by number of short breaks descending, limited to top 100

**Assumptions:**
- A break of less than 8 hours between trips is considered inadequate rest
- Only gaps between consecutive trips for the same driver are considered

---

### Mart 3 — `holiday_impact`
**Business Question:** Do US public holidays have an impact on the number of taxi trips?

**Methodology:**
- Aggregated total trips per day across the dataset
- Created a reference list of US federal holidays (New Year's Day, Independence Day, Thanksgiving, Christmas) for 2023–2024
- Joined daily trip counts with the holiday list to flag each day as a holiday or normal day

**Assumptions:**
- Only US federal public holidays are considered
- Holiday dates are hardcoded based on the years covered by the dataset

---

## 📈 Looker Studio Dashboard

The dashboard is organised into 3 pages:

| Page | Chart Type | Key Insight |
|---|---|---|
| **Top Tip Earners** | Scatter plot (Trips vs Tips, bubble = Revenue) | Identifies high-performing drivers by tip earnings |
| **Overworkers** | Heatmap table | Flags drivers working dangerously long hours |
| **Holiday Impact** | Bar chart + Summary table | Shows whether public holidays increase or decrease trip demand |

### 🔗 [View Live Dashboard](https://datastudio.google.com/reporting/3c014c82-5693-423c-ab06-6e29266496aa)

---

## ⚙️ CI/CD Pipeline

The project uses **GitHub Actions** to automatically run dbt models on every push to the `main` branch.

### How it works:
1. Code is pushed to the `main` branch on GitHub
2. GitHub Actions detects the new commit and triggers the workflow
3. The workflow installs dbt, configures the BigQuery connection, and runs:
   - `dbt debug` — verifies the connection
   - `dbt run` — executes all models and updates BigQuery
   - `dbt test` — validates data quality
4. If any step fails, the pipeline turns red and the run is flagged

### Authentication:
Instead of using a service account key file (which was restricted by GCP organisation policy), this project uses **Workload Identity Federation** — a secure, keyless authentication method that allows GitHub Actions to authenticate directly with GCP without exposing any credentials.

---

## 🚀 How to Run Locally

### Prerequisites
- Google Cloud account with BigQuery access
- Python 3.8+
- dbt-bigquery installed

### Setup

```bash
# Install dbt
pip install dbt-bigquery --user

# Clone the repo
git clone https://github.com/danielshamsul/chicago-taxi-analysis.git
cd chicago-taxi-analysis

# Configure your dbt profile
nano ~/.dbt/profiles.yml
```

Add this to your `profiles.yml` (replace with your GCP project ID):

```yaml
chicago_taxi_analysis:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: YOUR_GCP_PROJECT_ID
      dataset: chicago_taxi_dbt
      location: US
      threads: 4
```

```bash
# Authenticate with GCP
gcloud auth application-default login

# Test connection
dbt debug

# Run all models
dbt run
```

---

## 📝 Assumptions & Limitations

- The dataset ends around 2023, so "last 90 days" is relative to the most recent date in the data, not today
- Taxi IDs are anonymised — no personal identification is possible
- US federal holidays only are considered for the holiday impact analysis
- Holiday dates are hardcoded for 2023–2024; extending the date range would require updating the holiday list
- The overworker analysis assumes continuous operation — drivers who log off and return are still counted if their gap is under 8 hours

---

## 🙋 About This Project

This assessment was completed as part of the Time DotCom Data Analytics Engineer hiring process. It represents my first hands-on experience with dbt, built upon my existing foundation in GCP, SQL, and CI/CD from my previous role at Maxis. I approached this as both a technical challenge and a learning opportunity, and I look forward to continuing to grow in this space.
