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

## Analysis and Business Insights

### 1. Customer Distribution by Age Group
```sql
WITH age_group_table AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            WHEN age BETWEEN 56 AND 65 THEN '56-65'
            WHEN age > 65 THEN '65 Above'
        END AS ageGroup
    FROM netflix_customer
)
SELECT
    ageGroup AS 'Age Group',
    COUNT(*) AS 'Total Customers'
FROM age_group_table
GROUP BY ageGroup
ORDER BY ageGroup;
```

**How it works**: 
- Uses a Common Table Expression (CTE) to create age groups using CASE statements
- Groups customers by age ranges and counts total customers in each segment
- Orders results by age group for better readability

**Insight**: The minimum age of customers in dataset is 18 and maximum is 70. Largest number of customers is in range 56-65 (Later work life/Early retirement). Smallest number of customers is from above 65 group (Retired customers).

### 2. Churn Rate Analysis in each Age Group
```sql
WITH age_group_table AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            WHEN age BETWEEN 56 AND 65 THEN '56-65'
            WHEN age > 65 THEN '65 Above'
        END AS ageGroup,
        churned
    FROM netflix_customer
)
SELECT
    ageGroup AS "Age Group",
    COUNT(*) AS "Total Customers",
    ROUND(SUM(CAST(churned AS int)) * 100.0 / COUNT(*), 2) AS "Churn Rate %"
FROM age_group_table
GROUP BY ageGroup
ORDER BY ageGroup;
```

**How it works**:
- Uses the same age grouping logic as the previous query
- Calculates churn rate by dividing churned customers by total customers in each age group and transforms into percentage.
- The `churned` column contains binary values (0 or 1) where 1 means churned and 0 means active

**Insight**: This analysis shows which age groups have higher churn rates, allowing retention techniques for high-risk age groups.

### 3. Gender Distribution by Subscription Type (Method 1)
```sql
SELECT 
    subscription_type,
    gender, 
    COUNT(*) AS "Total Customers"
FROM netflix_customer 
GROUP BY subscription_type, gender
ORDER BY subscription_type;
```

**How it works**:
- Groups customers by both subscription type and gender
- Counts total customers for each unique combination
- Orders by subscription type for organized output

**Insight**: Helps identify gender-based preferences for subscription tiers, which can inform targeted marketing campaigns.

### 4. Gender Distribution by Subscription Type (Method 2 - Static Pivot)
```sql
SELECT subscription_type, Male, Female, Other
FROM
    (SELECT 
        subscription_type, 
        gender,
        1 AS cnt
    FROM netflix_customer) AS SOURCE
    PIVOT(
        SUM(cnt)
        FOR gender IN ([Male], [Female], [Other])
    ) AS PVT;
```
This query provides the same analysis as Method 1 but presents the data in a pivot table format for easier comparison.

**How it works**:
- Creates a source table with subscription type, gender, and a count column
- Uses PIVOT to transform gender values into columns
- Sums the count for each gender-subscription combination
- Results in a two way table view with subscription types as rows and genders as columns

**Insight**: The pivot format makes it easier to compare gender distribution across subscription types at a glance.

### 5. Device Preferences by Region (Dynamic Pivot)
```sql
DECLARE @cols AS NVARCHAR(MAX), @query AS NVARCHAR(MAX);

WITH devices AS (
    SELECT device
    FROM netflix_customer
    GROUP BY device
)

-- Generate dynamic columns
SELECT @cols = COALESCE(@cols + ', ', '') + QUOTENAME(device) 
FROM devices

-- Put dynamic columns into the SELECT statement
SET @query = 
    'SELECT 
        region, ' + @cols + '
    FROM (
        SELECT 
            device,
            region,
            1 AS cnt
        FROM netflix_customer
    ) AS source
    PIVOT (
        SUM(cnt)
        FOR device IN (' + @cols + ')
    ) AS pvt';

EXECUTE(@query);
```
This query creates a dynamic pivot table showing device preferences across different regions.

**How it works**:
- Uses dynamic SQL to create columns for all device types automatically
- First identifies all unique devices in the dataset
- Constructs a pivot query dynamically to handle varying device types
- Executes the constructed query to show device usage by region

**Insight**: Reveals regional preferences for viewing devices, which can inform content delivery optimization and device-specific feature development.

### 6. Churn Rates by Subscription Types
```sql
SELECT
    subscription_type AS "Subscription Type",
    COUNT(*) AS "Total Customers",
    ROUND(SUM(CAST(churned AS int)) * 100.0 / COUNT(*), 2) AS "Churn Rate %"
FROM netflix_customer
GROUP BY subscription_type
ORDER BY subscription_type;
```

**How it works**:
- Groups customers by subscription type
- Calculates total customers and churn rate for each subscription tier
- Converts churned bit values to integers for calculation
- Rounds churn rate to 2 decimal places for readability

**Insight**: Premium and Standard subscription users stick to their subscription. New customers join with Basic subscription and stop after trying one or few months. This suggests Basic subscribers may need better onboarding or upgrade incentives.

### 7. Subscription Type by Customer Age Group
```sql
WITH age_group_table AS (
    SELECT
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            WHEN age BETWEEN 56 AND 65 THEN '56-65'
            WHEN age > 65 THEN '65 Above'
        END AS ageGroup,
        subscription_type
    FROM netflix_customer
)
SELECT
    ageGroup AS "Age Group",
    ROUND(SUM(CASE WHEN subscription_type = 'Basic' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS "Basic Subscribers (%)",
    ROUND(SUM(CASE WHEN subscription_type = 'Standard' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS "Standard Subscribers (%)",
    ROUND(SUM(CASE WHEN subscription_type = 'Premium' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS "Premium Subscribers (%)"
FROM age_group_table
GROUP BY ageGroup
ORDER BY ageGroup;
```

**How it works**:
- Creates age groups using CTE
- Uses conditional aggregation to calculate percentage of each subscription type within each age group
- Rounds percentages to 2 decimal places for clean presentation

**Insight**: Reveals subscription preferences across age demographics, helping identify which age groups prefer premium features and which are price-sensitive.

### 8. Customer Segmentation Based on Usage Pattern
```sql
WITH customer_vs_group AS (
    SELECT 
        customer_id,
        CASE
            WHEN age BETWEEN 18 AND 25 THEN '18-25'
            WHEN age BETWEEN 26 AND 35 THEN '26-35'
            WHEN age BETWEEN 36 AND 45 THEN '36-45'
            WHEN age BETWEEN 46 AND 55 THEN '46-55'
            WHEN age BETWEEN 56 AND 65 THEN '56-65'
            WHEN age > 65 THEN '65 Above'
        END AS age_group,
        subscription_type,
        watch_hours,
        AVG(watch_hours) OVER (PARTITION BY 
            CASE
                WHEN age BETWEEN 18 AND 25 THEN '18-25'
                WHEN age BETWEEN 26 AND 35 THEN '26-35'
                WHEN age BETWEEN 36 AND 45 THEN '36-45'
                WHEN age BETWEEN 46 AND 55 THEN '46-55'
                WHEN age BETWEEN 56 AND 65 THEN '56-65'
                WHEN age > 65 THEN '65 Above'
            END, 
            subscription_type
        ) AS group_avg_watch_hours
    FROM netflix_customer
    WHERE churned='0'
)
SELECT 
    customer_id,
    age_group,
    subscription_type,
    watch_hours,
    ROUND(group_avg_watch_hours, 2) AS group_avg_watch_hours,
    ROUND(ABS(watch_hours - group_avg_watch_hours), 2) AS difference,
    ROUND((ABS(watch_hours - group_avg_watch_hours) / group_avg_watch_hours) * 100, 2) AS percentage_difference,
    CASE 
        WHEN watch_hours > group_avg_watch_hours * 1.2 THEN 'High User'
        WHEN watch_hours < group_avg_watch_hours * 0.8 THEN 'Low User'
        ELSE 'Typical User'
    END AS user_type
FROM customer_vs_group
ORDER BY percentage_difference DESC;
```
This query segments existing customers as High, Low, and Typical users based on their watch hours relative to the average in their age group and subscription type.

**How it works**:
- Uses window functions to calculate average watch hours for each age group and subscription type combination
- Compares individual customer watch hours to their group average
- Calculates absolute and percentage differences
- Classifies customers as High User (>120% of group average), Low User (<80% of group average), or Typical User
- Only includes active customers (churned='0')

**Insight**: Enables targeted engagement strategies for different user types - retention efforts for low users, loyalty programs for high users, and upgrade campaigns for typical users.

### 9. Monthly Revenue by Region (Cumulative Total)
```sql
WITH region_monthly_revenue AS (
    SELECT
        region,
        ROUND(SUM(monthly_fee), 2) as monthlyRev
    FROM
        netflix_customer
    WHERE churned = '0'
    GROUP BY region
)
SELECT
    region,
    monthlyRev,
    SUM(monthlyRev) OVER(ORDER BY region) AS "Cumulative Total"
FROM region_monthly_revenue;
```
This query calculates monthly revenue by region and shows cumulative totals to understand regional revenue contribution.

**How it works**:
- Filters for active customers only (churned = '0')
- Sums monthly fees by region
- Uses window function to calculate running cumulative total
- Orders by region for consistent cumulative calculation

**Insight**: Identifies high-revenue regions and shows progressive revenue accumulation, helping prioritize regional marketing investments.

### 10. Revenue Lost Due to Churn by Region
```sql
WITH region_monthly_revenue AS (
    SELECT
        region,
        ROUND(SUM(monthly_fee), 2) as monthlyRev
    FROM
        netflix_customer
    WHERE churned = '1'
    GROUP BY region
)
SELECT
    region,
    monthlyRev,
    SUM(monthlyRev) OVER(ORDER BY region) AS "Cumulative Total"
FROM region_monthly_revenue;
```
This query calculates the monthly revenue loss due to customer churn by region.

**How it works**:
- Filters for churned customers only (churned = '1')
- Sums monthly fees that were lost due to churn by region
- Calculates cumulative revenue loss across regions
- Provides insight into the financial impact of churn

**Insight**: Evaluates the impact of churn in revenue of region.

### 11. High Risk Customer Identification
```sql
CREATE VIEW netflix_customer_with_age_group 
AS
SELECT 
    customer_id,
    age,
    subscription_type,
    watch_hours,
    last_login_days,
    churned,
    CASE
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        WHEN age BETWEEN 56 AND 65 THEN '56-65'
        WHEN age > 65 THEN '65+'
        ELSE 'Unknown'
    END AS age_group
FROM netflix_customer;

WITH churned_profile AS (
    SELECT
        age_group,
        subscription_type,
        AVG(watch_hours) AS churned_group_avg_watch_hours,
        AVG(last_login_days) AS churned_avg_last_login_days,
        COUNT(*) AS churned_count
    FROM netflix_customer_with_age_group
    WHERE churned = '1'
    GROUP BY age_group, subscription_type
)
SELECT
    c.customer_id,
    c.age_group,
    c.subscription_type,
    c.watch_hours,
    cp.churned_group_avg_watch_hours,
    c.last_login_days,
    cp.churned_avg_last_login_days,
    cp.churned_count,
    CASE
        WHEN cp.churned_group_avg_watch_hours IS NULL THEN 'Unknown Risk'
        WHEN c.watch_hours <= cp.churned_group_avg_watch_hours 
            AND c.last_login_days >= cp.churned_avg_last_login_days
                THEN 'High Risk'
        WHEN c.watch_hours <= cp.churned_group_avg_watch_hours * 1.2 
            OR c.last_login_days >= cp.churned_avg_last_login_days * 0.8
                THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level
FROM netflix_customer_with_age_group c
LEFT JOIN churned_profile cp
    ON cp.age_group = c.age_group
    AND cp.subscription_type = c.subscription_type
WHERE c.churned = '0';
```
This query identifies active customers who are at high risk of churning based on behavioral patterns of customers who have already churned.

**How it works**:
- Creates a view with age groups for easier analysis
- Builds a profile of churned customers by calculating average watch hours and last login days for each age group and subscription type combination
- Compares active customers against churned customer profiles
- Assigns risk levels based on similarity to churned customer patterns:
  - High Risk: Low watch hours AND high days since last login
  - Medium Risk: Moderate deviation from churned patterns
  - Low Risk: Significantly different from churned patterns

**Insight**: Enables proactive retention campaigns by identifying customers likely to churn before they actually do, allowing for targeted interventions to improve retention rates.

## Key Findings and Recommendations

1. **Age Demographics**: The 56-65 age group represents the largest customer segment, suggesting Netflix should focus on content and features appealing to this demographic.

2. **Subscription Tier Strategy**: Basic subscribers show higher churn rates, indicating need for better onboarding and upgrade incentives.

3. **Regional Revenue Impact**: Revenue loss analysis by region helps prioritize retention efforts where they'll have the most financial impact.

4. **Predictive Churn Prevention**: The risk assessment model enables proactive customer retention by identifying high-risk customers before they churn.

5. **Usage-Based Segmentation**: Customer segmentation based on viewing patterns allows for personalized engagement strategies.

This comprehensive analysis provides Netflix with actionable insights to improve customer retention, optimize subscription offerings, and maximize revenue across different demographics and regions.

## Conclusion

This SQL-based analysis demonstrates how data-driven insights can inform strategic decisions for streaming platforms. The comprehensive approach covering demographic analysis, churn prediction, revenue impact assessment, and customer segmentation provides a robust framework for understanding customer behavior and implementing targeted retention strategies.
