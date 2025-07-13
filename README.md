# Netflix Customer Data Analysis

## Problem Statement
The streaming platforms like Netflix experience customer churn across different demographics and subscription types, resulting in significant revenue loss. The company needs to identify key factors driving customer attrition and develop data-driven strategies to improve customer retention and optimize subscription offerings.

## Dataset and Data Quality
This dataset is sourced from kaggle. It contains data simulating customer behaviour. It has 5000 records with 14 features useful for churn prediction, business insighgts and customer segmentation.

Dataset link: https://www.kaggle.com/datasets/abdulwadood11220/netflix-customer-churn-dataset/

## Project Objectives
- To build local database, connect database and create table to save our data for analysis
- To insert data into table from csv file.
- To perform following analysis and build insights from the data.
      - Customer distribution by Age Group

```sql
CREATE TABLE netflix_customer(
    customer_id VARCHAR(50) PRIMARY KEY,
    age INT,
    gender VARCHAR(8),
    subscription_type VARCHAR(16),
    watch_hours DECIMAL(10,2),
    last_login_days INT,
    region VARCHAR(16),
    device VARCHAR(16),
    monthly_fee DECIMAL(10,2),
    churned BIT,
    payment_method VARCHAR(16),
    number_of_profiles INT,
    avg_watch_time_per_day DECIMAL(10,2),
    favorite_genre VARCHAR(16)
);
```
