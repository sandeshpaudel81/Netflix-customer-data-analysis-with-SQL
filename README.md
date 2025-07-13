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
