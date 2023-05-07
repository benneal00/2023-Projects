-- Assess table
SELECT * FROM housing;

-- Use ALTER TABLE and UPDATE to add/change columns and clean data
ALTER TABLE housing
ADD COLUMN street_city VARCHAR(50) AFTER county;

UPDATE housing
SET street_city = substring(address, 1, LOCATE('MI 4', address) -3 );

ALTER TABLE housing
RENAME COLUMN address TO state_zip;

UPDATE housing
SET state_zip = substring(state_zip,LOCATE('MI 4', state_zip));

UPDATE housing
SET year_built = ''
WHERE year_built = 0;


			-- What is the average price of homes by county?
-- Use the GROUP BY clause to group the data by county and AVG function to calculate the average price of homes by county.
SELECT 
    county, AVG(price) AS average_price
FROM
    housing
GROUP BY county;

			-- What is the average days on market for homes by condition?
/* Use GROUP BY clause to group the data by condition, and AVG function to calculate the average days on market for homes by condition. 
End with ORDER BY clause to sort the results by the second column.*/
SELECT 
    `condition`, AVG(days_on_market) AS days
FROM
    housing
GROUP BY `condition`
ORDER BY 2;

			-- What is the average price of homes with a water view compared to those without a water view?
-- Group the data by water_view and use the AVG function to calculate the average price of homes with or without a water view.
SELECT 
    water_view, AVG(price)
FROM
    housing
GROUP BY 1;

			-- What is the average home size for homes with more than 3 bedrooms?
/* This query uses the WHERE clause to filter the data by the number of bedrooms and uses the ROUND and AVG functions to calculate the 
average home size of homes with more than 3 bedrooms.*/
SELECT 
    ROUND(AVG(homesize_sqft), 0) AS sqft
FROM
    housing
WHERE
    bed > 3;

			-- What is the most expensive and least expensive home in each county?
-- Use the GROUP BY clause to group the data by county and use the MAX and MIN functions to find the most and least expensive homes in each county.
SELECT 
    county, MAX(price) AS max_price, MIN(price) AS min_price
FROM
    housing
GROUP BY 1;

			-- What is the average days on market for homes with a water view compared to those without a water view, for each county?
/* Group the data by county and water_view and use the AVG function to calculate the average days on market for homes with 
or without a water view, for each county.*/
SELECT 
    county, water_view, AVG(days_on_market)
FROM
    housing
GROUP BY 1 , 2;

			-- What is the average price per square foot of homes below and above 1500 sqft?
/* Use the CASE statement to categorize the data by home size, and the AVG function to calculate the average price per square foot 
of homes above and below 1500 sqft.*/
SELECT 
	CASE
		WHEN homesize_sqft >= 1500 THEN '1500 SQFT or Greater'
        WHEN homesize_sqft < 1500 THEN 'Less Than 1500 SQFT'
        END AS home_size,
	AVG(price/ homesize_sqft) AS avg_price_per_sqft
FROM housing
GROUP BY 1;

			-- What is the median price of homes by number of bathrooms and bedrooms? 
-- This query calculates the median price of homes using a subquery and the @row_num variable to sort the data and find the median.
SELECT AVG(price) AS median_value
FROM (
  SELECT  price, @row_num:=@row_num+1 AS row_num, @total_rows:=@row_num 
               FROM housing, (SELECT @row_num:=0) a
               ORDER BY price
) AS b
WHERE row_num IN (FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2));

			-- What is the percentage of homes in each condition category?
-- Use the GROUP BY clause to group the data by condition and the COUNT function to calculate the percentage of homes in each condition category.
SELECT `condition`, 
ROUND(100 * COUNT(*)/ (SELECT COUNT(*) FROM housing), 2) as percentage 
FROM housing 
GROUP BY `condition`;

			-- What is the number, percentge of total, and average price of homes that were built before 1990 in each county? -----------
/* Group the data by county and use the COUNT, ROUND, and AVG functions to calculate the number, percentage, and average price of homes 
that were built before 1990 in each county.*/
SELECT 
    county,
    COUNT(CASE
        WHEN year_built < 1990 THEN 1
    END) AS num_homes_built_before_1990,
    ROUND(COUNT(CASE
                WHEN year_built < 1990 THEN 1
            END) / COUNT(*) * 100,
            2) AS pct_of_total_homes,
    AVG(CASE
        WHEN year_built < 1990 THEN price
    END) AS avg_price_of_homes_built_before_1990
FROM
    housing
GROUP BY county;

			-- What is the average price of homes by county, and how does it rank compared to other counties?
-- The RANK function is used to rank the average price of homes by county and GROUP BY clause is used to group the data by county
SELECT county, AVG(Price) AS avg_price, 
RANK() OVER (ORDER BY AVG(price) DESC) AS price_rank
FROM housing
GROUP BY county;

			-- How does the average price per square foot vary by number of bedrooms and bathrooms?
-- This query groups the data by number of bedrooms and bathrooms and uses the AVG function to calculate the average price per square foot.
SELECT 
    bed, bathroom, AVG(price / homesize_sqft) AS price_per_sqft
FROM
    housing
GROUP BY 1 , 2
ORDER BY 1;

			-- Which county has the highest percentage of homes with a water view?
-- Use COUNT to determine the number of homes with water view and total number of homes. Grouped by county.
SELECT 
    county,
    100 * COUNT(CASE
        WHEN water_view = 'yes' THEN 1
    END) / COUNT(*) AS percentage
FROM
    housing
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

			-- How does the average price of homes with a water view compare to the average price of homes without a water view in each county?
/* Group the data by county and use the AVG function and CASE statement to compare the average price of homes with and without a 
water view in each county.*/
SELECT county,
	AVG(CASE WHEN water_view = 'yes' THEN price END) AS waterview,
	AVG(CASE WHEN water_view = 'no' THEN price END) AS 'no waterview'
FROM housing
GROUP BY 1;

			-- What is the percentage of homes that have a lot size larger than the average lot size in each county?
/* Use the WITH clause to calculate the average lot size and then calculate the percentage of homes that have a lot size 
larger than the average lot size in each county using the GROUP BY clause.*/
WITH a AS(

SELECT id, county, lotsize_acres, 
ROUND(AVG(lotsize_acres) OVER( PARTITION BY county ORDER BY county), 3) 
AS avg_lotsize 
FROM housing
ORDER BY id)
SELECT county, ROUND(100 * COUNT(CASE WHEN lotsize_acres > avg_lotsize THEN 1 END) / COUNT(*), 3) AS percentage 
FROM a
GROUP BY 1;

			-- What is the average year built and price for homes that dont have both heating and cooling (or both have null values)
/* Use the WHERE clause to filter the data by homes that don't have both heating and cooling, and AVG function to 
calculate the average year built and price for these homes.*/
SELECT ROUND(AVG(year_built), 0), AVG(price) FROM housing
WHERE (heating = 'no' or '') AND (cooling = 'no' or '') AND year_built != '';

			-- What zip code has the largest total lot size 
-- The SUM function adds the total lot size and orderded descending and limited to 1 to show largest.
SELECT state_zip, SUM(lotsize_acres) AS total_lot_size FROM housing
GROUP BY state_zip
ORDER BY 2 DESC
LIMIT 1


