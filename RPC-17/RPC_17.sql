Use codebasis;
Select * from ad_revenue;
Select * from Sales;
Select * from city_readiness;

CREATE TABLE city (
    city_id VARCHAR(10) PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    tier VARCHAR(10) NOT NULL
);

INSERT INTO city (city_id, city, state, tier) VALUES
('C001', 'lucknow', 'Uttar Pradesh', 'Tier 2'),
('C002', 'Delhi', 'DELHI', 'Tier 1'),
('C003', 'bhopal', 'Madhya Pradesh', 'Tier 2'),
('C004', 'Patna', 'BIHAR', 'Tier 2'),
('C005', 'jaipur', 'Rajasthan', 'Tier 2'),
('C006', 'Mumbai', 'MAHARASHTRA', 'Tier 1'),
('C007', 'ranchi', 'JHARKHAND', 'Tier 3'),
('C008', 'kanpur', 'UTTAR PRADESH', 'Tier 2'),
('C009', 'Ahmedabad', 'GUJARAT', 'Tier 1'),
('C010', 'Varanasi', 'Uttar Pradesh', 'Tier 2');

CREATE TABLE ad_category (
    ad_category_id VARCHAR(10) PRIMARY KEY,
    standard_ad_category VARCHAR(50) NOT NULL,
    category_group VARCHAR(50) NOT NULL,
    example_brands VARCHAR(100)
);

INSERT INTO ad_category (ad_category_id, standard_ad_category, category_group, example_brands) VALUES
('A001', 'Government', 'Public Sector', 'LIC, SBI'),
('A002', 'FMCG', 'Commercial Brands', 'HUL, Britannia'),
('A003', 'Real Estate', 'Private Sector', 'DLF, Lodha'),
('A004', 'Automobile', 'Commercial Brands', 'Tata Motors, Maruti');

ALTER TABLE ad_revenue
ADD CONSTRAINT ad_category_rule
FOREIGN KEY (ad_category)
REFERENCES ad_category(ad_category_id);

ALTER TABLE ad_revenue
MODIFY ad_category VARCHAR(10);

ALTER TABLE ad_category
MODIFY ad_category_id VARCHAR(10);

ALTER TABLE ad_revenue
ADD CONSTRAINT ad_category_rule
FOREIGN KEY (ad_category)
REFERENCES ad_category(ad_category_id);

ALTER TABLE city_readiness
MODIFY city_id VARCHAR(10);

ALTER TABLE city
MODIFY city_id VARCHAR(10);

ALTER TABLE city_readiness
ADD CONSTRAINT city_category_rule
FOREIGN KEY (city_id)
REFERENCES city(city_id);

ALTER TABLE sales
MODIFY city_id VARCHAR(10);

ALTER TABLE sales
ADD CONSTRAINT city_sales_category_rules
FOREIGN KEY (city_id)
REFERENCES city(city_id);

ALTER TABLE pilot
MODIFY city_id VARCHAR(10);

ALTER TABLE pilot
ADD CONSTRAINT city_piot_category_rules
FOREIGN KEY (city_id)
REFERENCES city(city_id);

CREATE INDEX idx_ad_revenue_category
ON ad_revenue(ad_category);

CREATE INDEX idx_readiness_city
ON city_readiness(city_id);

CREATE INDEX idx_sales_city
ON sales(city_id);

CREATE INDEX idx_pilot_city
ON pilot(city_id);

SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'codebasis'



AND REFERENCED_TABLE_NAME IS NOT NULL;


SELECT 
    table_name, 
    column_name, 
    data_type, 
    column_key
FROM information_schema.columns
WHERE table_schema = 'codebasis'
ORDER BY table_name;
ALTER TABLE city_readiness
DROP COLUMN MyUnknownColumn;

ALTER TABLE pilot
DROP COLUMN MyUnknownColumn;

ALTER TABLE sales
CHANGE `ï»¿edition_ID` edition_id VARCHAR(20);

Select * from Sales;

-- Business Q1

WITH circulation_change AS (
    SELECT
        s.city_id,
        c.city AS city_name,
        s.Month,
        s.Net_Circulation,
        s.Net_Circulation - 
        LAG(s.Net_Circulation) OVER (
            PARTITION BY s.city_id
            ORDER BY s.Month
        ) AS mom_change
    FROM sales s
    JOIN city c
        ON s.city_id = c.city_id
)

SELECT 
    city_name,
    Month,
    mom_change
FROM circulation_change
WHERE mom_change < 0
ORDER BY mom_change ASC
LIMIT 3;

-- Business Q2

WITH cte AS (
    SELECT 
        REGEXP_SUBSTR(quarter, '[0-9]{4}') AS Year,
        ad_category AS Category,
        ad_revenue,

        SUM(ad_revenue) OVER (
            PARTITION BY REGEXP_SUBSTR(quarter, '[0-9]{4}'),ad_category
        ) AS Category_Revenue,

        SUM(ad_revenue) OVER (
            PARTITION BY REGEXP_SUBSTR(quarter, '[0-9]{4}')
        ) AS Year_Revenue

    FROM ad_revenue
),
CTE1 AS (
SELECT 
    Year,Category as "Category_Name",
    Round(Category_Revenue,1) as "Category_Revenue",
    Round(Year_Revenue,1) as "Year_Revenue",
    round((Category_Revenue/Year_Revenue)*100,1) "pct_of_year_total"
FROM cte
GROUP BY Year,Category,Category_Revenue,Year_Revenue
ORDER BY Year
)
Select Year,Category_Name,Category_Revenue,Lag(Category_Revenue) over 
(Partition by Category_Name ), Year_Revenue,Lag(Year_Revenue) over
(partition by Year),Lag(Year_Revenue) over
(partition by Category_Name), pct_of_year_total
from CTE1;

-- Business Question 3

WITH cte AS (
    SELECT c.city,
           s.month,
           s.`Copies Sold`,
           s.Net_Circulation
    FROM sales s
    JOIN City c 
         ON s.city_id = c.city_id  
    WHERE RIGHT(s.Month,2) = '24'
),
cte1 AS (
    SELECT City,
           Month,
           `Copies Sold`,
           Net_Circulation,
           Net_Circulation * 1.0 / `Copies Sold` AS Eff,
           ROW_NUMBER() OVER (
               ORDER BY Net_Circulation * 1.0 / `Copies Sold` DESC
           ) AS Rank_
    FROM cte
)
SELECT *
FROM cte1;
Select * from sales order by City_Id ;

-- Business Question 5 
-- Business Question 5

WITH C1 AS (
    SELECT 
        UPPER(C.City) AS City,
        RIGHT(S.Month,2) AS Year,
        SUM(S.Net_Circulation) AS Net_Circulation
    FROM sales S
    RIGHT JOIN City C 
         ON S.City_id = C.City_id  
    GROUP BY 
        UPPER(C.City),
        RIGHT(S.Month,2)
)

SELECT *, LAG(Net_Circulation) Over 
(Order by City, Year) as "Previous_Net_Circulation",
Net_Circulation-LAG(Net_Circulation) Over 
(Order by City, Year)
FROM C1;


-- Business Question 6
Select * from City;
Select * from City_Readiness;
Select * from ad_category;

with B6 AS (
SELECT 
    City,
    Avg((COALESCE(literacy_rate,0) 
     + COALESCE(smartphone_penetration,0) 
     + COALESCE(internet_penetration,0))) / 3 AS Readiness
FROM City c
LEFT JOIN City_Readiness r 
ON c.city_id = r.city_id where left(Quarter,4) = 2021 group by City
)
Select City,Readiness, row_number() over (order by Readiness desc) as "readiness_rank_desc" from B6;




--- Completed