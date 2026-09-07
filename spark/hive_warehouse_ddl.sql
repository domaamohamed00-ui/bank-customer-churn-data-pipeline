CREATE DATABASE IF NOT EXISTS customer_churn_db;
USE customer_churn_db;

CREATE TABLE IF NOT EXISTS dim_customer (
    cust_key INT,
    customer_id INT,
    surname STRING,
    gender STRING,
    date_of_birth DATE,
    age INT,
    geography STRING,
    credit_score INT,
    tenure INT,
    join_date DATE,
    estimated_salary DOUBLE,
    has_cr_card INT,
    is_active_member INT,
    is_churned BOOLEAN,
    dw_start_date DATE,
    dw_end_date DATE,
    is_current BOOLEAN
)
USING PARQUET
LOCATION '/user/student/Capstone_project/gold/dim_customer';

CREATE TABLE IF NOT EXISTS dim_date (
    date_key INT,
    full_date DATE,
    calendar_month INT,
    month_name STRING,
    calendar_quarter INT,
    calendar_year INT
)
USING PARQUET
LOCATION '/user/student/Capstone_project/gold/dim_date';

CREATE TABLE IF NOT EXISTS fact_customer_monthly_activity_df (
    activity_key BIGINT,
    cust_key INT,
    date_key INT,
    offers_received_count BIGINT,
    offers_accepted_count BIGINT,
    tickets_opened_count BIGINT,
    critical_tickets_count BIGINT,
    total_resolution_time_hrs DOUBLE,
    ending_monthly_balance DOUBLE,
    active_products_count BIGINT,
    load_timestamp TIMESTAMP
)
USING PARQUET
LOCATION '/user/student/Capstone_project/gold/fact_customer_monthly_activity';
