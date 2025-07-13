-- Netflix customer demographics and churn analysis

-- Dataset from https://www.kaggle.com/datasets/abdulwadood11220/netflix-customer-churn-dataset/

-- Creating table netflix_customer

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

-- Inserting bulk data into netflix_customer table

BULK INSERT netflix_customer
FROM 'C:\Users\sande\Desktop\datasets\Netflix-customer-churn\netflix_customer_churn.csv'
WITH
( 
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-----------------------------------------------------------------------------------------

-- Customer distribution by Age Group

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

-- The minimum age of customers in dataset is 18 and maximum is 70.
-- This query counts total number of customers in each age bracket.
-- Largest number of customers is in range 56-65 (Later work life/Early retirement)
-- Smallest number of customers is from above 65 group (Retired customers)

--------------------------------------------------------------------------------------

-- Churn Rate Analysis in each Age Group

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

-- The 'churned' column contains value either 0 or 1
-- 1 means 'churned' and 0 means 'not churned'
-- This query calculates churn rate for each age group
-- Mathematically, no. of churned customers / total customers in that age group

----------------------------------------------------------------------------------------

-- Gender distribution by subscription-type (Method 1)

SELECT 
    subscription_type,
    gender, 
    COUNT(*) AS "Total Customers"
FROM netflix_customer 
GROUP BY subscription_type, gender
ORDER BY subscription_type;

-- This query shows how gender is distributed across different subscription types
-- Method 1 uses traditional GROUP BY approach to show gender breakdown
-- Results show if any particular gender prefers specific subscription tiers
-- Helps identify target demographics for subscription upgrades

----------------------------------------------------------------------------------------

-- Gender distribution by subscription-type (Method 2 - Static Pivot)

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

SELECT region, count(*)
FROM netflix_customer
GROUP BY region;

-- Method 2 uses PIVOT to create a 2 way tabulation of the same data
-- Each gender becomes a column showing number of customers for each subscription type
-- This output is more clear and readable for cross-comparison across genders

----------------------------------------------------------------------------------------

-- Device preferences by region (Pivot with dynamic columns)

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

-- This dynamic pivot query automatically adapts to any number of devices in the dataset (unlike prespecified genders in above query)
-- Unlike static pivot, it doesn't require knowing device names beforehand
-- Shows which devices are popular in each region for targeted marketing
-- Helps identify regional technology usage patterns

----------------------------------------------------------------------------------------

 -- Churn rates by subscription types

SELECT
    subscription_type AS "Subscription Type",
    COUNT(*) AS "Total Customers",
    ROUND(SUM(CAST(churned AS int)) * 100.0 / COUNT(*), 2) AS "Churn Rate %"
FROM netflix_customer
GROUP BY subscription_type
ORDER BY subscription_type;

-- This analysis reveals which subscription tiers have highest customer attrition
-- Lower churn rates in Premium/Standard suggest better value perception
-- Basic subscribers likely testing the service before committing or upgrading
-- High Basic churn indicates need for better onboarding or pricing strategy

----------------------------------------------------------------------------------------

-- Subscription type by customers age-group

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

-- This query shows subscription preferences across different age brackets
-- Percentage breakdown helps in easier comparison
-- Younger customers may prefer Basic due to price sensitivity
-- Older customers might choose Premium for better quality and features
-- Useful for age-targeted marketing campaigns and pricing strategies

---------------------------------------------------------------------------------------------------------------------------------

-- Segmenting existing customers as High, Low and Typical User based on their watch hour with respect to average in their age group

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

-- This analysis segments active customers by their viewing behavior relative to same aged customers
-- High Users: Watch 20% more than their age group average
-- Low Users: Watch 20% less than average - at risk of churning
-- Typical Users: Within 20% of average
-- Helps prioritize retention efforts and identify upselling opportunities

---------------------------------------------------------------------------------------------------

-- Monthly Revenue by Region

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

-- This statement calculates current monthly revenue from active customers by region
-- Running total shows progressive revenue contribution across regions

---------------------------------------------------------------------------------------------------

-- Revenue Lost due to churn by Region

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

-- This analysis calculates monthly revenue loss from churned customers by region
-- Shows the impact of customer attrition in revenue

---------------------------------------------------------------------------------------------------

-- Identifying high risk customers who is likely to churn
GO
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
GO
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

-- This predictive analysis uses churned customer profiles as benchmarks for risk scores
-- Compares active customers against historical churn patterns in their age segment
-- High Risk: Match both low watch hours AND high login gaps of churned users
-- Medium Risk: Match either low engagement OR login patterns
-- Low Risk: Healthy engagement unlike churned customer profiles
-- Enables proactive retention before customers actually churn