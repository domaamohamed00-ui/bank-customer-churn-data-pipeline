CREATE DATABASE IF NOT EXISTS customer_churn;
USE customer_churn;

SET GLOBAL local_infile = 1;

CREATE TABLE IF NOT EXISTS customer (
    customer_id INT PRIMARY KEY,
    surname VARCHAR(100),
    credit_score INT,
    geography VARCHAR(50),
    gender VARCHAR(20),
    age INT,
    tenure INT,
    has_cr_card BOOLEAN,
    is_active_member BOOLEAN,
    estimated_salary DECIMAL(15,2),
    exited BOOLEAN,
    date_of_birth DATE,
    join_date DATE,
    email VARCHAR(255),
    phone_number VARCHAR(30),
    national_id VARCHAR(50),
    address VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS customer_usage (
    usage_id INT PRIMARY KEY,
    customer_id INT,
    product_type VARCHAR(50),
    monthly_balance DECIMAL(15,2),
    num_products INT,
    date DATE,
    CONSTRAINT fk_customer_usage FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

CREATE TABLE IF NOT EXISTS offers (
    offer_id INT PRIMARY KEY,
    customer_id INT,
    offer_type VARCHAR(50),
    accepted BOOLEAN,
    date_offered DATE,
    CONSTRAINT fk_customer_offers FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

LOAD DATA LOCAL INFILE '/media/sf_Shared_Folder/Banking_DataSet/Customer.csv'
INTO TABLE customer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    customer_id,
    surname,
    credit_score,
    geography,
    gender,
    age,
    tenure,
    has_cr_card,
    is_active_member,
    estimated_salary,
    exited,
    date_of_birth,
    join_date,
    email,
    phone_number,
    national_id,
    address
);

LOAD DATA LOCAL INFILE '/media/sf_Shared_Folder/Banking_DataSet/Usage.csv'
INTO TABLE customer_usage
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    usage_id,
    customer_id,
    product_type,
    monthly_balance,
    num_products,
    date
);

LOAD DATA LOCAL INFILE '/media/sf_Shared_Folder/Banking_DataSet/Offers.csv'
INTO TABLE offers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    offer_id,
    customer_id,
    offer_type,
    accepted,
    date_offered
);
