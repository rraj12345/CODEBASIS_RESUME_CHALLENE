use trips_db;
-- Q1
Select city_name ,sum(fare_amount) from dim_city d Join fact_trips f on d.city_id=f.city_id 
group by city_name  order by sum(fare_amount) desc limit 3;

-- Q2
Select city_name ,sum(fare_amount) from dim_city d Join fact_trips f on d.city_id=f.city_id 
group by city_name  order by sum(fare_amount) asc limit 3;

-- Q3

SELECT city_name,avg(distance_travelled_km),SUM(fare_amount) / count(trip_id) AS 'AvgFareTrip' FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by city_name order by AvgFareTrip desc limit 2;
 
SELECT city_name,avg(distance_travelled_km),SUM(fare_amount) / count(trip_id) AS 'AvgFareTrip' FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by city_name order by AvgFareTrip asc limit 2;
 
 -- q3 
 Select  passenger_type,city_name,avg(passenger_rating)  FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by passenger_type,city_name order by avg(passenger_rating) desc limit 1;
 
  Select  passenger_type,city_name,avg(passenger_rating)  FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by passenger_type,city_name order by avg(passenger_rating)  limit 1;
 
 Select  passenger_type,city_name,avg(driver_rating)  FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by passenger_type,city_name order by avg(driver_rating) desc limit 1;
 
 Select  passenger_type,city_name,avg(driver_rating)  FROM 
dim_city d Join fact_trips f
on
d.city_id = f.city_id
 group by passenger_type,city_name order by avg(driver_rating)  limit 1;
 
 -- Q4 
CREATE  VIEW monthly_trips AS
SELECT 
    dc.city_name AS city_name,
    DATE_FORMAT(ft.date, '%M') AS trip_month, -- Extracting the month name
    COUNT(*) AS total_trips
FROM 
    fact_trips ft
JOIN 
    dim_city dc
ON 
    ft.city_id = dc.city_id
GROUP BY 
    city_name, trip_month;


 CREATE  VIEW peak_low_months AS
SELECT 
    city_name,
    MAX(total_trips) AS peak_trips,
    MIN(total_trips) AS low_trips
FROM 
    monthly_trips
GROUP BY 
    city_name;
    
SELECT 
    plm.city_name,
    mt_peak.trip_month AS peak_dd_month,
    mt_low.trip_month AS low_dd_month
FROM 
    peak_low_months plm
JOIN 
    monthly_trips mt_peak
ON 
    plm.city_name = mt_peak.city_name AND plm.peak_trips = mt_peak.total_trips
JOIN 
    monthly_trips mt_low
ON 
    plm.city_name = mt_low.city_name AND plm.low_trips = mt_low.total_trips order by plm.city_name;

-- Q6
CREATE VIEW repeat_passenger_frequency AS
SELECT 
    d.city_name,
    rtd.trip_count,
    SUM(rtd.repeat_passenger_count) AS total_repeat_passengers,
    ROUND(
        SUM(rtd.repeat_passenger_count) * 100.0 / SUM(SUM(rtd.repeat_passenger_count)) 
        OVER (PARTITION BY d.city_name), 2
    ) AS percentage_of_repeat_passengers
FROM 
    dim_repeat_trip_distribution rtd
JOIN 
    dim_city d ON rtd.city_id = d.city_id
GROUP BY 
    d.city_name, rtd.trip_count;

-- View data to identify cities contributing to higher trip frequencies
SELECT * 
FROM repeat_passenger_frequency
ORDER BY percentage_of_repeat_passengers DESC;


-- Q7 

-- Create a view to evaluate monthly target achievements





