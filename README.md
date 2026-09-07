````markdown
# 🏦 Banking Customer Churn Data Lake & Analytics Pipeline

An end-to-end Big Data engineering project designed to ingest, process, store, and analyze banking customer data to identify the key drivers of customer churn.

The solution follows a **Medallion Architecture (Bronze → Silver → Gold)** implemented on a traditional **HDFS-based Data Lake**, with **Apache Hive** used to build the analytical data warehouse in the Gold layer.

The final datasets are consumed by **Power BI** to provide business insights into customer activity, churn behavior, support resolution performance, and promotional offer effectiveness.

---

## 📌 Business Problem

Customer retention is a major challenge for retail banks. Understanding why customers become inactive or leave the bank allows organizations to take proactive retention actions and improve customer lifetime value.

This project integrates customer information, account activity, support tickets, and promotional offer data to identify behavioral patterns associated with customer churn.

### 🎯 Business Objectives

- Identify the main factors associated with customer churn.
- Analyze the relationship between customer activity and churn.
- Measure the impact of customer support resolution performance on churn.
- Analyze promotional offer acceptance across customer segments.
- Understand how the number of active products affects customer engagement.
- Build a centralized analytical warehouse for BI reporting.

---

# 🏗️ Architecture

The project uses a traditional **Data Lake architecture** with three processing layers:

```text
                         DATA SOURCES
                              │
             ┌────────────────┴────────────────┐
             │                                 │
             ▼                                 ▼
        MariaDB OLTP                    Support Ticket CSV
             │                                 │
             │ Sqoop                           │ NiFi
             │                                 │
             └────────────────┬────────────────┘
                              ▼
                         HDFS DATA LAKE
                              │
                              ▼
                    🥉 BRONZE LAYER
                       Raw Data
                              │
                              ▼
                       Apache PySpark
                              │
                ┌─────────────┼─────────────┐
                │             │             │
            Cleaning      Validation    Deduplication
                │             │             │
                └─────────────┼─────────────┘
                              ▼
                    🥈 SILVER LAYER
                  Clean & Standardized Data
                              │
                              ▼
                         Aggregations
                              │
                              ▼
                     🥇 GOLD LAYER
                              │
                       Apache Hive
                              │
                              ▼
                   Star Schema Warehouse
                              │
                              ▼
                         Power BI
                              │
                              ▼
                    Business Insights
````

![Data Lake Architecture](docs/images/pipeline_architecture.jpeg)

> **Architecture Note:** This project uses a traditional HDFS-based **Data Lake**. It is **not a Data Lakehouse**, as it does not use lakehouse table formats such as Delta Lake, Apache Iceberg, or Apache Hudi.

---

# 🔄 Data Ingestion

## 1. 🗄️ Relational Data Ingestion — Apache Sqoop

Operational banking data is stored in **MariaDB**.

Apache Sqoop is used to extract relational data from MariaDB and load it into HDFS for distributed processing.

### Ingestion Flow

```text
MariaDB
   │
   ▼
Apache Sqoop
   │
   ▼
HDFS
   │
   ▼
Bronze Layer
```

The Sqoop import process is automated using:

```bash
bash scripts/sqoop_import.sh
```

### Key Features

* Parallel data extraction using multiple mappers.
* Batch ingestion from MariaDB.
* Distributed storage on HDFS.
* Parquet-based storage for efficient analytical processing.

---

## 2. 📂 Support Ticket Ingestion — Apache NiFi

Customer support ticket data is provided as CSV files.

Apache NiFi is used to automate the ingestion and transformation of these files before storing them in HDFS.

### NiFi Flow

```text
GetFile
   │
   ▼
ConvertRecord
   │
   ▼
CSV → Avro
   │
   ▼
Schema Validation
   │
   ▼
PutHDFS
```

![NiFi Flow](docs/images/nifi_flow.jpeg)

### Main Responsibilities

* Monitor incoming CSV files.
* Convert CSV records to Avro.
* Validate records against the defined schema.
* Store processed data in HDFS.
* Automate the batch ingestion process.

The Avro schema is available at:

```text
scripts/ticket_schema.avsc
```

---

# 🥉 Bronze Layer — Raw Data

The Bronze layer represents the **raw landing zone** of the Data Lake.

Data is stored with minimal modification after ingestion from the source systems.

### Characteristics

* Raw source data.
* HDFS-based distributed storage.
* Source data preserved for traceability.
* Parquet datasets from relational sources.
* Avro datasets from support ticket ingestion.
* Minimal transformations.

```text
MariaDB ──► Sqoop ──► HDFS ──► Bronze

CSV ──► NiFi ──► HDFS ──► Bronze
```

The Bronze layer acts as the foundation for all downstream processing.

---

# 🥈 Silver Layer — Clean & Standardized Data

Apache PySpark is used to transform the raw Bronze datasets into clean and standardized datasets.

### Data Processing

The Silver layer performs:

* Schema enforcement.
* Data type casting.
* Missing-value handling.
* Duplicate record removal.
* Data cleansing.
* Column standardization.
* Data validation.

### Processing Flow

```text
Bronze
   │
   ├── Schema Enforcement
   │
   ├── Type Casting
   │
   ├── Null Handling
   │
   ├── Deduplication
   │
   └── Data Validation
          │
          ▼
       Silver
```

The main PySpark implementation is available in:

```text
notebooks/01_data_cleaning_and_warehousing.ipynb
```

---

# 🥇 Gold Layer — Hive Data Warehouse

The Gold layer contains **business-ready analytical data**.

Apache Hive is used to create the analytical warehouse following a **Star Schema**.

The warehouse consists of:

* One central fact table.
* Two dimension tables.

---

# ⭐ Star Schema

The warehouse follows the following structure:

![Star Schema](docs/images/star_schema.jpeg)

### Schema Overview

| Table                            | Type      | Description                                                                |
| -------------------------------- | --------- | -------------------------------------------------------------------------- |
| `Dim_Customer`                   | Dimension | Customer profile, demographic, and historical attributes                   |
| `Dim_Date`                       | Dimension | Calendar and date attributes                                               |
| `Fact_Customer_Monthly_Activity` | Fact      | Monthly customer activity, support, promotional offer, and balance metrics |

---

## 👤 Dim_Customer

The customer dimension stores customer profile attributes and is designed to support historical tracking.

| Column             | Data Type | Key | Description                              |
| ------------------ | --------- | --- | ---------------------------------------- |
| `cust_key`         | BIGINT    | PK  | Surrogate customer key                   |
| `customer_id`      | STRING    | BK  | Business/customer identifier             |
| `surname`          | STRING    | —   | Customer surname                         |
| `gender`           | STRING    | —   | Customer gender                          |
| `date_of_birth`    | DATE      | —   | Customer date of birth                   |
| `age`              | INT       | —   | Customer age                             |
| `geography`        | STRING    | —   | Customer geographic location             |
| `credit_score`     | INT       | —   | Customer credit score                    |
| `tenure`           | INT       | —   | Customer tenure                          |
| `join_date`        | DATE      | —   | Customer joining date                    |
| `estimated_salary` | DECIMAL   | —   | Estimated customer salary                |
| `has_cr_card`      | BOOLEAN   | —   | Whether the customer has a credit card   |
| `is_active_member` | BOOLEAN   | —   | Whether the customer is an active member |
| `is_churned`       | BOOLEAN   | —   | Customer churn status                    |
| `dw_start_date`    | DATE      | —   | Dimension record effective start date    |
| `dw_end_date`      | DATE      | —   | Dimension record effective end date      |
| `is_current`       | BOOLEAN   | —   | Indicates the current dimension record   |

### 🔑 Dimension Design

`cust_key` is a **surrogate key**, while `customer_id` represents the original business key.

The following columns are included to support historical dimension tracking:

```text
dw_start_date
dw_end_date
is_current
```

This design supports a **Slowly Changing Dimension (SCD) Type 2** approach for maintaining historical customer records.

---

## 📅 Dim_Date

The date dimension provides standard calendar attributes for analytical reporting.

| Column             | Data Type | Key | Description                                  |
| ------------------ | --------- | --- | -------------------------------------------- |
| `date_key`         | INT       | PK  | Date key used to identify each calendar date |
| `full_date`        | DATE      | —   | Full calendar date                           |
| `calendar_month`   | INT       | —   | Month number                                 |
| `month_name`       | STRING    | —   | Month name                                   |
| `calendar_quarter` | INT       | —   | Calendar quarter                             |
| `calendar_year`    | INT       | —   | Calendar year                                |

The date dimension supports time-based analysis such as:

* Monthly churn trends.
* Year-over-year comparisons.
* Quarterly analysis.
* Monthly customer activity.

---

# 📊 Fact_Customer_Monthly_Activity

The central fact table stores aggregated customer activity at a **monthly grain**.

### Grain

> **One record represents one customer's activity for a specific month.**

| Column                      | Data Type | Key      | Description                           |
| --------------------------- | --------- | -------- | ------------------------------------- |
| `activity_key`              | BIGINT    | PK       | Unique activity record key            |
| `cust_key`                  | BIGINT    | FK       | References `Dim_Customer`             |
| `date_key`                  | INT       | FK       | References `Dim_Date`                 |
| `offers_received_count`     | INT       | Measure  | Number of promotional offers received |
| `offers_accepted_count`     | INT       | Measure  | Number of promotional offers accepted |
| `tickets_opened_count`      | INT       | Measure  | Number of support tickets opened      |
| `critical_tickets_count`    | INT       | Measure  | Number of critical support tickets    |
| `total_resolution_time_hrs` | DECIMAL   | Measure  | Total support-ticket resolution time  |
| `ending_monthly_balance`    | DECIMAL   | Measure  | Customer balance at month end         |
| `active_products_count`     | INT       | Measure  | Number of active products             |
| `load_timestamp`            | TIMESTAMP | Metadata | Warehouse data load timestamp         |

---

# 🔗 Table Relationships

The fact table connects the two dimensions through foreign keys:

```text
                    ┌─────────────────────┐
                    │    Dim_Customer     │
                    │                     │
                    │ PK cust_key         │
                    └──────────┬──────────┘
                               │
                               │ 1 : N
                               │
                               ▼
                    ┌──────────────────────────────┐
                    │ Fact_Customer_Monthly_       │
                    │ Activity                     │
                    │                              │
                    │ PK activity_key              │
                    │ FK cust_key                  │
                    │ FK date_key                  │
                    │                              │
                    │ Business Measures            │
                    └──────────────┬───────────────┘
                                   │
                                   │ N : 1
                                   │
                                   ▼
                         ┌─────────────────┐
                         │    Dim_Date     │
                         │                 │
                         │ PK date_key     │
                         └─────────────────┘
```

### Relationship Summary

```text
Dim_Customer
     │
     │ cust_key
     ▼
Fact_Customer_Monthly_Activity
     ▲
     │ date_key
     │
Dim_Date
```

---

# 📈 Business Analytics

The Gold layer provides the foundation for analyzing customer churn and engagement.

## 🔹 Customer Activity & Churn

Customer activity is analyzed using indicators such as:

* Active membership status.
* Number of active products.
* Monthly account balance.
* Customer tenure.
* Credit score.

Inactive customers show a significantly higher churn rate, highlighting the importance of proactive re-engagement strategies.

---

## 🔹 Support Resolution & Churn

Customer support behavior is analyzed using:

* Number of tickets opened.
* Number of critical tickets.
* Total resolution time.
* Customer churn status.

Longer resolution times, particularly for critical support cases, can be analyzed against customer attrition to identify potential service-related churn drivers.

---

## 🔹 Product Engagement

The number of active products is used as an important customer engagement metric.

The analysis indicates that customer engagement is strongest around customers holding **two active products**, providing a potential opportunity for targeted cross-selling and retention strategies.

---

## 🔹 Promotional Offer Effectiveness

Promotional activity is analyzed using:

```text
offers_received_count
offers_accepted_count
```

This allows the business to calculate metrics such as:

* Offer acceptance rate.
* Offers received per customer.
* Promotional engagement.
* Offer acceptance by customer segment.

---

# 📊 Power BI

Power BI consumes the Gold-layer analytical datasets to provide business-facing dashboards.

### Dashboard Analysis

The dashboard focuses on:

* 📌 Overall customer churn.
* 👥 Customer segmentation.
* 💳 Product utilization.
* 💰 Monthly balance trends.
* 🎧 Support ticket performance.
* ⏱️ Resolution time analysis.
* 📣 Promotional offer effectiveness.
* 📈 Customer activity trends.

Dashboard screenshots are available under:

```text
docs/images/
```

---

# 🧰 Technology Stack

| Technology         | Role                                     |
| ------------------ | ---------------------------------------- |
| **MariaDB**        | OLTP / source database                   |
| **Apache Sqoop**   | Relational data ingestion                |
| **Apache NiFi**    | File-based data ingestion                |
| **Apache Avro**    | Data serialization and schema validation |
| **HDFS**           | Distributed Data Lake storage            |
| **Apache PySpark** | Distributed data processing              |
| **Apache Hive**    | Data warehouse and SQL analytics         |
| **Parquet**        | Columnar data storage                    |
| **Power BI**       | Business intelligence and visualization  |
| **Python**         | Data engineering and analytics           |
| **SQL**            | Database and warehouse development       |
| **Bash**           | Pipeline automation                      |

---

# 📁 Project Structure

```text
banking-customer-churn/
│
├── data/
│   └── raw/
│       └── # Source raw CSV datasets
│
├── sql/
│   ├── 01_mariadb_schema.sql
│   │   └── # MariaDB DDL and data loading
│   │
│   └── 02_hive_warehouse_ddl.sql
│       └── # Hive Gold-layer Star Schema DDL
│
├── scripts/
│   ├── sqoop_import.sh
│   │   └── # Automated Sqoop ingestion script
│   │
│   └── ticket_schema.avsc
│       └── # Avro schema for NiFi
│
├── notebooks/
│   ├── 01_data_cleaning_and_warehousing.ipynb
│   │   └── # PySpark Bronze → Silver → Gold pipeline
│   │
│   └── 02_business_insights_and_marts.ipynb
│       └── # Business insights and analytical queries
│
├── docs/
│   ├── Final_Documentation.docx
│   ├── Customer_Churn_Presentation.pptx
│   └── images/
│       ├── pipeline_architecture.jpeg
│       ├── nifi_flow.jpeg
│       ├── star_schema.jpeg
│       └── # Power BI dashboard screenshots
│
├── requirements.txt
├── .gitignore
└── README.md
```

---

# 🔄 End-to-End Data Flow

```text
                    ┌───────────────┐
                    │    MariaDB    │
                    └───────┬───────┘
                            │
                          Sqoop
                            │
                            ▼
                    ┌───────────────┐
                    │     HDFS      │
                    └───────┬───────┘
                            │
                            ▼
                      🥉 BRONZE
                       Raw Data
                            │
                            │
┌──────────────────┐        │
│ Support CSV Files│        │
└────────┬─────────┘        │
         │                  │
        NiFi                │
         │                  │
         └────────┬─────────┘
                  │
                  ▼
                 HDFS
                  │
                  ▼
             Apache PySpark
                  │
                  ▼
             🥈 SILVER
        Clean & Standardized
                  │
                  ▼
          Business Aggregation
                  │
                  ▼
              🥇 GOLD
                  │
                  ▼
          Apache Hive Warehouse
                  │
                  ▼
             Star Schema
                  │
                  ▼
              Power BI
                  │
                  ▼
        Business Insights
```

---

# 📋 Data Engineering Concepts Demonstrated

This project demonstrates practical implementation of:

* Data Lake architecture.
* Medallion Architecture.
* Batch data ingestion.
* Distributed data processing.
* ETL pipeline development.
* Schema enforcement.
* Data quality handling.
* Null-value handling.
* Deduplication.
* Parquet storage.
* HDFS distributed storage.
* Dimensional modeling.
* Star Schema.
* Slowly Changing Dimensions (SCD Type 2) design.
* Fact table design.
* Date dimension design.
* Hive data warehousing.
* Business data marts.
* BI integration.

---

# 📚 Documentation

Detailed technical documentation is available in:

```text
docs/Final_Documentation.docx
```

The executive presentation is available in:

```text
docs/Customer_Churn_Presentation.pptx
```

---

# 🚀 Future Improvements

The following enhancements could make the platform more production-ready:

* Implement incremental ingestion instead of full loads.
* Introduce Apache Airflow for pipeline orchestration.
* Add automated data-quality checks.
* Implement data lineage and metadata management.
* Optimize Hive tables using partitioning and bucketing.
* Add Spark performance optimization.
* Implement automated pipeline monitoring and alerting.
* Introduce Apache Kafka for real-time ingestion.
* Build a Machine Learning model for churn prediction.
* Generate customer-level churn-risk scores.
* Automate Power BI dataset refresh.

---

# 🎯 Project Objective

The objective of this project is to demonstrate how Big Data technologies can be combined to build an end-to-end **Banking Customer Churn Data Lake and Analytics Platform**.

The pipeline starts with raw operational and support data, processes it through a **Bronze → Silver → Gold** architecture, builds a dimensional warehouse using Hive, and finally exposes business insights through Power BI.

```text
Raw Data
   ↓
Ingestion
   ↓
HDFS Data Lake
   ↓
Bronze
   ↓
PySpark Processing
   ↓
Silver
   ↓
Business Aggregation
   ↓
Gold
   ↓
Hive Star Schema
   ↓
Power BI
   ↓
Customer Churn Insights
```

> **Final Architecture:** Traditional HDFS Data Lake + Medallion Architecture + Hive Data Warehouse + Power BI.
>
> **This project is not a Data Lakehouse.**

```
```
