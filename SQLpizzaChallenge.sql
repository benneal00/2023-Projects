-- Assess data stored in each table
SELECT * FROM customer_orders;
SELECT * FROM pizza_names; 
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;
SELECT * FROM runner_orders;
SELECT * FROM runners;

-- #1 How many unique customer orders were made?
	-- Using the count and distinct functions along with an alias to retrieve this infromation
SELECT COUNT(DISTINCT(order_id)) AS unique_orders FROM customer_orders;

-- #2 How many successful orders were delivered by each runner?
	-- Filter the data using where function. I want the count of the orders that do not have 'null' as a value in the pickup_time column
SELECT runner_id, COUNT(order_id) AS successful_orders
FROM runner_orders
WHERE pickup_time != 'null'
GROUP BY 1;

-- #3 How many of each type of pizza was delivered?
	-- This information is stored on three different tables. Two inner joins are used to connect the three tables
SELECT pname.pizza_name, COUNT(run_ord.runner_id) AS delivered_count
FROM customer_orders  AS cust_ord
JOIN pizza_names AS pname ON cust_ord.pizza_id = pname.pizza_id
JOIN runner_orders AS run_ord ON cust_ord.order_id = run_ord.order_id
WHERE run_ord.pickup_time != 'null'
GROUP BY 1;

-- #4 How many Vegetarian and Meatlovers were ordered by each customer?
	-- Join the pizza_names table to the customer_orders table and group by pizza name and customer id
SELECT cust_ord.customer_id, pname.pizza_name, COUNT(cust_ord.order_id) AS order_count
FROM customer_orders  AS cust_ord
JOIN pizza_names AS pname ON cust_ord.pizza_id = pname.pizza_id
GROUP BY 1,2
ORDER BY 1;

-- #5 What was the maximum number of pizzas delivered in a single order?
	-- Find max by using COUNT, ORDER, and LIMIT. Filter data for only orders that were delivered
SELECT customer_orders.order_id, COUNT(customer_orders.order_id) AS max_delivered FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.pickup_time != 'null'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- #6 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
	-- Use CASE to assign 1 or 0 to specifieded cases and add using SUM
SELECT customer_id, 
SUM(
CASE WHEN (exclusions = '' or exclusions = 'null') 
	AND (extras = '' or extras = 'null' or extras IS NULL) THEN 1 ELSE 0 END) AS no_changes,
SUM(CASE WHEN (exclusions != '' AND exclusions != 'null') 
	OR (extras != '' AND extras != 'null' AND extras IS NOT NULL) THEN 1 ELSE 0 END) AS changes_made
FROM customer_orders
JOIN runner_orders ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.pickup_time != 'null'
group by 1;

-- #7 How many pizzas were delivered that had both exclusions and extras?
	-- A cte lets me store a result and query from it. First I filter the data and then extract the information I need from my cte
WITH exclusions AS 
(SELECT * FROM customer_orders
WHERE (exclusions !='' AND exclusions != 'null') AND (extras != '' AND extras != 'null' AND extras IS NOT NULL) 
)
SELECT COUNT(exc.order_id) AS 'count'
FROM exclusions exc
JOIN runner_orders ON exc.order_id = runner_orders.order_id
WHERE runner_orders.pickup_time != 'null';

-- #8 What was the total volume of pizzas ordered for each hour of the day?
	-- The EXTRACT function is used to get the hour of day. Using COUNT and grouping by the hour to get the result
SELECT EXTRACT( HOUR FROM order_time) AS hour_of_day, COUNT(order_id) AS count_per_hour 
FROM customer_orders
GROUP BY 1
ORDER BY 1;

-- #9 What was the volume of orders for each day of the week?
	-- Use DAYNAME to get the name of the week day
SELECT DAYNAME(order_time) AS day_of_week, COUNT(order_id) AS count_per_day
FROM customer_orders
GROUP BY 1;

												-- PART TWO

-- #1 How many runners signed up for each 1 week period? 
	-- I used the BETWEEN clause  to filter the dates inside of a SUM(CASE()) statement.
SELECT 
SUM(CASE 
	WHEN registration_date BETWEEN '2021-01-01' AND '2021-01-07' THEN 1 ELSE 0 END) AS Week_1, 
SUM( CASE
		WHEN registration_date BETWEEN '2021-01-08' AND '2021-01-14' THEN 1 ELSE 0 END) AS Week_2,
SUM(CASE
	WHEN registration_date BETWEEN '2021-01-15' AND '2021-01-21' THEN 1 ELSE 0 END) AS Week_3
FROM runners;

-- #2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
	-- I used 2 cte's to get the data I needed. Absolute value is used to return positive numbers and I rounded the average to 2 decimal places
WITH minutes AS
(
SELECT ro.runner_id, EXTRACT(minute FROM co.order_time) AS order_min, EXTRACT(minute FROM ro.pickup_time) AS runner_min FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
GROUP BY 1,2,3
),
total AS
(
SELECT runner_id, ABS(runner_min - order_min) AS diff FROM minutes
WHERE runner_min IS NOT NULL)
SELECT runner_id, ROUND(AVG(diff), 2) AS average_minutes FROM total
GROUP BY 1;

-- #3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
	-- I used substring to make the result easier to read and timediff to find the difference between to given times
SELECT co.order_id, COUNT(co.order_id) AS num_of_orders, SUBSTRING(TIMEDIFF(co.order_time,ro.pickup_time), 5,5) AS total_time
 FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE SUBSTRING(TIMEDIFF(co.order_time,ro.pickup_time), 5,5) IS NOT NULL
GROUP BY 1,3;

-- #4 What was the average distance travelled for each customer?
	-- I cleaned the data to make it easier to work with
		-- SET SQL_SAFE_UPDATES = 0;
		-- UPDATE runner_orders SET distance = REPLACE(distance, 'km', '') ;
		--  UPDATE runner_orders SET cancellation = REPLACE(cancellation, 'null','');
		-- SET SQL_SAFE_UPDATES = 1;
	
SELECT customer_id, AVG(distance) AS avg_distance FROM runner_orders
JOIN customer_orders ON runner_orders.order_id = customer_orders.order_id
WHERE runner_orders.pickup_time != 'null'
GROUP BY 1;

-- #5 What is the successful delivery percentage for each runner?
	-- Use cte's to get success count and total count. Then divide and multiply by 100 to get percentage
WITH s AS
(
SELECT runner_id,COUNT(runner_id) AS success FROM runner_orders
WHERE cancellation ='' or cancellation IS NULL
GROUP BY 1),
 t as
 (
SELECT runner_id, COUNT(runner_id) AS total FROM runner_orders
GROUP BY 1)
SELECT s.runner_id, success/total *100 AS success_rate FROM s
JOIN t ON s.runner_id = t.runner_id;


