# Netflix Customer Data Analysis

## Problem Statement
The streaming platforms like Netflix experience customer churn across different demographics and subscription types, resulting in significant revenue loss. The company needs to identify key factors driving customer attrition and develop data-driven strategies to improve customer retention and optimize subscription offerings.

## Dataset and Data Quality
This dataset is sourced from kaggle. It contains data simulating customer behaviour. It has 5000 records with 14 features useful for churn prediction, business insighgts and customer segmentation.
*There are no null values.*

Dataset link: https://www.kaggle.com/datasets/abdulwadood11220/netflix-customer-churn-dataset/

## Project Objectives
- To build local database, connect database and create table to save our data for analysis
- To insert data into table from csv file.
- To perform following analysis and build insights from the data.\
  	- Customer distribution by Age Group
  	- Churn Rate Analysis in each Age Group
  	- Gender distribution by subscription-type (Method 1)
  	- Gender distribution by subscription-type (Method 2 - Static Pivot)
  	- Device preferences by region (Pivot with dynamic columns)
  	- Churn rates by subscription types
  	- Subscription type by customers age-group
  	- Customer Segmentation based on usage pattern
  	- Monthly Revenue by Region (Cumulative Total)
  	- Revenue Lost due to churn by Region
  	- Identification of high churn-risk customers

## Tools/Websites Used
- SQL Server
- SQL Server Management Studio
- Kaggle

## Database and Tables

### Create Table `netflix_customer`

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
This `CREATE TABLE` statement creates new table in our database to store customer data. The column names are kept same as the headers in csv file. 

### Insert data into Table `netflix_customer`

```sql
BULK INSERT netflix_customer
FROM 'C:\Users\sande\Desktop\datasets\Netflix-customer-churn\netflix_customer_churn.csv'
WITH
( 
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);
```
`BULK INSERT` inserts large records from local flat file into table. `FIRSTROW=2` means customer record starts from second line. `FIELDTERMINATOR` is used to specify what separates two field values. `ROWTERMINATOR` specifies end of record. `TABLOCK` specifies required lock is acquired in table level.
