# 🚕 Chicago Taxi Trips — Data Analytics Assessment
**Submitted by:** Muhammad Daniel Shamsul
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
            │
            ▼
    GitHub Actions CI/CD (auto-deploys on every push)
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
│   │   └── stg_taxi_trips.sql        ← Cleans and filters raw data
│   └── marts/
│       ├── top_tip_earners.sql       ← Top 100 drivers by tip earnings
│       ├── overworkers.sql           ← Top 100 drivers with insufficient rest
│       └── holiday_impact.sql        ← Trip demand by day type and holiday
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

> Taxi IDs are anonymised to protect driver privacy in compliance with data protection regulations.

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
- Filtered trips to the last 90 days using the most recent available date in the dataset rather than today's date, since the dataset ends around 2023
- Grouped by `taxi_id` and aggregated total tips, average tip per trip, and total revenue
- Ranked by total tips descending, limited to top 100

**Key Finding:** The majority of top earners completed 400–700 trips. High trip volume does not guarantee high tips — service quality matters more than quantity.

---

### Mart 2 — `overworkers`
**Business Question:** Who are the top 100 drivers working the most shifts without adequate rest?

**Methodology:**
- Used a SQL window function (`LAG`) to calculate the time gap between each driver's consecutive trips
- Gaps of 5 or more hours (300 minutes) are treated as shift boundaries — the end of one shift and the start of the next
- The 8-hour rest rule is applied only to between-shift gaps, not normal breaks between trips within the same shift
- Drivers are ranked by number of shifts with less than 8 hours rest

**Assumption:** A gap of 5+ hours between trips is used as a proxy for the end of a shift, since the dataset does not record explicit shift start/end times. This threshold should be validated with domain experts in a production environment.

**Key Finding:** All top 100 flagged drivers average between 350–400 minutes (5.8–6.7 hours) of rest between shifts — consistently below the 8-hour threshold.

---

### Mart 3 — `holiday_impact`
**Business Question:** Do public holidays and day of week affect taxi trip demand?

**Methodology:**
- Aggregated total trips per day across the dataset
- Classified each day into one of three categories: Weekday, Weekend, or Holiday (Holiday takes priority over Weekend if both apply)
- Created a reference list of US federal holidays for 2023–2024
- Extracted day of week name and number for weekly pattern analysis

**Key Findings:**
- Weekday average: 34,142 trips
- Weekend average: 30,366 trips (11% lower than weekdays)
- Holiday average: 6,346 trips (81% lower than weekdays)
- Christmas has the lowest demand at 4,226 trips
- Independence Day is the highest holiday at 8,511 trips
- Friday is consistently the peak demand day across the week

**Limitation:** Holiday dates are hardcoded for 2023–2024 only. Extending coverage would require updating the holiday list or integrating a public holiday API.

---

## 📈 Looker Studio Dashboard

| Page | Charts | Key Insight |
|---|---|---|
| **Top Tip Earners** | Scatter plot (Trips vs Tips) | High volume ≠ high tips |
| **Overworkers** | Bar chart + Scatter plot | Systemic rest violations across top 100 |
| **Holiday Impact** | Bar chart + Day of week + Holiday table | 81% demand drop on holidays |

### 🔗 [View Live Dashboard](https://datastudio.google.com/reporting/3c014c82-5693-423c-ab06-6e29266496aa)

---

## ⚙️ CI/CD Pipeline

The project uses **GitHub Actions** to automatically run dbt models on every push to the `main` branch.

### Pipeline Steps:
1. Code pushed to `main` branch
2. GitHub Actions triggers automatically
3. dbt is installed on a fresh Ubuntu environment
4. BigQuery connection is verified (`dbt debug`)
5. All models are executed (`dbt run`)
6. Data quality tests are run (`dbt test`)
7. Pipeline turns green (success) or red (failure)

### Authentication:
This project uses **Workload Identity Federation** instead of service account key files. This was implemented after GCP's organisation policy blocked key file creation — Workload Identity Federation is the more secure, keyless alternative recommended by Google, allowing GitHub Actions to authenticate directly with GCP without exposing any credentials.

---

## 🚀 How to Run Locally

### Prerequisites
- Google Cloud account with BigQuery access
- Python 3.8+

### Setup

```bash
# Install dbt
pip install dbt-bigquery --user
export PATH="$HOME/.local/bin:$PATH"

# Clone the repo
git clone https://github.com/danielshamsul/chicago-taxi-analysis.git
cd chicago-taxi-analysis

# Authenticate with GCP
gcloud auth application-default login

# Configure dbt profile
mkdir -p ~/.dbt
nano ~/.dbt/profiles.yml
```

Add this to your `profiles.yml`:

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
# Test connection
dbt debug

# Run all models
dbt run
```

---

## 📝 Assumptions & Limitations

- "Last 90 days" for tip earners is relative to the most recent date in the dataset, not today's date
- Taxi IDs are anonymised — no personal identification is possible
- Shift boundaries in the overworkers model are inferred using a 5-hour gap threshold — this should be validated with domain experts
- Holiday dates are hardcoded for 2023–2024 only
- Only US federal public holidays are considered

---

## 🙋 About This Project

This assessment was completed as part of the Time DotCom Data Analytics Engineer hiring process. It represents my first hands-on experience with dbt, built on my existing foundation in GCP, SQL, and CI/CD from my previous role at Maxis. I approached this as both a technical challenge and a learning opportunity — identifying and correcting methodological flaws along the way rather than just delivering the first working version.
