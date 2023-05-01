-- Assess tables and clean data.
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM purchases order by purchase_date;
DELETE FROM customers WHERE customer_id = 174;
ALTER TABLE products RENAME COLUMN cusine TO cuisine;

			-- How many customers does the meal kit companay have?
-- Use the COUNT() function and the DISTINCT keyword to ensure that each customer is only counted once.
SELECT COUNT(DISTINCT(customer_id) ) AS customers
FROM customers;

			-- What is the date of the first and most recent sale
-- MAX and MIN to determine the oldest and newest purchase
SELECT MIN(purchase_date) AS oldest_purchase, MAX(purchase_date) AS most_recent_purchase 
FROM purchases;

			-- What is the revenue for the meal kit company
-- Find the revenue by multiplying quantity and price and adding the results
SELECT SUM(purchases.quantity * products.price) AS total_revenue
FROM purchases 
JOIN products  USING(product_id);
																												
			-- What are the top 5 MOST popular meal kits by quantity sold?
-- Select the meal name and sum of quantity. Group by the meal name, order by total quantity and limit to 5
SELECT products.meal_name, products.meatless, SUM(purchases.quantity) AS total_meals 
FROM products 
JOIN purchases USING(product_id)
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 5;
            
            -- What are the top 5 LEAST popular meal kits by quantity sold?
-- Same query as above ordered by ASC
SELECT products.meal_name, products.meatless, SUM(purchases.quantity) AS total_meals 
FROM products 
JOIN purchases USING(product_id)
GROUP BY 1, 2
ORDER BY 3 ASC
LIMIT 5;

            -- What are the top 5 MOST popular meal kits by revenue?
-- Use SUM to find revenue for each product. Order and limit to find top 5
SELECT products.meal_name, products.meatless, SUM(purchases.quantity * products.price) AS revenue
FROM purchases 
JOIN products ON purchases.product_id = products.product_id
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 5;          
           
           -- What are the top 5 LEAST popular meal kits by revenue?
-- Same query as above ordered by ASC
 SELECT products.meal_name, products.meatless, SUM(purchases.quantity * products.price) AS revenue
FROM purchases 
JOIN products ON purchases.product_id = products.product_id
GROUP BY 1,2
ORDER BY 3 ASC
LIMIT 5;            
			
			-- What is the running total of revenue generated by each cuisine over time?       
 /*  This query uses the SUM() window function with PARTITION BY and ORDER BY clauses to 
 calculate the running total of revenue generated by each cuisine over time. */        
SELECT products.cuisine, purchases.purchase_date, 
SUM(purchases.quantity * products.price) OVER( PARTITION BY products.cuisine ORDER BY purchases.purchase_date) AS total
FROM products
JOIN purchases USING(product_id);

            -- What are the total meals purchased by age group
/* This query uses the CASE statement to group customers by age group, calculates the count 
of meals purchased for each age group. */
SELECT 
CASE
	WHEN YEAR(curdate())- YEAR(date_of_birth)  BETWEEN 18 AND 26 THEN '18 - 26'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 27 AND 35 THEN '27 - 35'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 36 AND 46 THEN '36 - 46'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 47 AND 59 THEN '47 - 59'
    ELSE '60 or older'
    END AS age_group,
    COUNT(purchases.product_id) AS num_purchases
    FROM customers
    JOIN purchases USING(customer_id)
    GROUP BY 1;

			-- What is the average quantity purchased by age group
/*This query is similar to the previous one, but instead of counting meals, it calculates the 
average quantity of meals purchased for each age group.*/
SELECT 
CASE
	WHEN YEAR(curdate())- YEAR(date_of_birth)  BETWEEN 18 AND 26 THEN '18 - 26'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 27 AND 35 THEN '27 - 35'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 36 AND 46 THEN '36 - 46'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 47 AND 59 THEN '47 - 59'
    ELSE '60 or older'
    END AS age_group,
    AVG(purchases.quantity) AS average_quantity
FROM customers
JOIN purchases USING(customer_id)
GROUP BY 1;

			-- What percentage of meals purchased were meatless
/* Select the count of purchases that are meatless divided by the total purchases. 
Use CONCAT add percentage and covert to string.*/
SELECT CONCAT( '%', 
ROUND(100 * (SELECT COUNT(*) 
FROM purchases 
JOIN products USING(product_id) 
WHERE products.meatless = 'yes') / COUNT(*), 2)) AS meatless_purchases 
FROM purchases;

			-- What age group purchased the most meatless meals
/* Uses theCASE statement from the query aboveCounts meatless purchases and orders the 
results by the total number of meatless purchases in descending order.*/
SELECT 
CASE
	WHEN YEAR(curdate())- YEAR(date_of_birth)  BETWEEN 18 AND 26 THEN '18 - 26'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 27 AND 35 THEN '27 - 35'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 36 AND 46 THEN '36 - 46'
    WHEN YEAR(curdate())- YEAR(date_of_birth) BETWEEN 47 AND 59 THEN '47 - 59'
    ELSE '60 or older'
    END AS age_group,
    COUNT(purchases.product_id) AS total_meatless_purchases
    FROM customers
    JOIN purchases USING(customer_id)
    JOIN products USING (product_id)
    WHERE products.meatless = 'yes'
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 1;

			-- What was the average quantity purchased by customers with children vs without
/*  groups customers by whether they have children or not and calculates the average quantity of meals 
purchased for each group. */
SELECT children, AVG(quantity) AS average_quantity
FROM purchases
JOIN customers USING (customer_id)
GROUP BY children;

			-- How much money was spent by income bracket, and how many customers belong to each bracket?
-- Group customers by income bracket and calculates the total revenue generated by each bracket and the number of customers in each bracket.
SELECT 
CASE
	WHEN income <= 50000 THEN 'lower class'
    WHEN income BETWEEN 50001 AND 100000 THEN 'middle class'
    WHEN income  >100000 THEN 'upper class'
	END AS income_bracket,
     SUM(purchases.quantity * products.price) AS total_revenue, COUNT(customers.customer_id) AS number_of_customers_in_class
    FROM customers
    JOIN purchases USING(customer_id)
    JOIN products USING(product_id)
    GROUP BY 1;

			-- What is the average price of meal kits purchased by customers with high income versus low income?
-- Group customers by income level and calculates the average price of meal kits purchased for each group.
SELECT 
CASE
	WHEN income <= 75000 THEN 'low income'
    WHEN income >75000 THEN 'high income'
    END AS income_level,
     AVG(products.price) AS average_meal_price
    FROM customers
    JOIN purchases USING(customer_id)
    JOIN products USING(product_id)
    GROUP BY 1;


			-- What is the total quantity of meal kits sold to male customers compared to female customers?
-- This query groups customers by gender and calculates the total quantity of meal kits sold to each group.
SELECT customers.gender, SUM(purchases.quantity) AS quantity FROM purchases
JOIN customers USING(customer_id)
GROUP BY 1;

			/*What are the top 3 most popular meal kits by revenue, 
            and what is the average purchase quantity for each of these meal kits among customers with children?*/
/* uses a subquery to select the top 3 most popular meal kits by revenue and joins the products, purchases, and 
customers tables to calculate the average purchase quantity*/ 
 SELECT meal_name, AVG(purchases.quantity) AS average_quantity, 
 SUM(products.price * purchases.quantity) AS revenue FROM purchases
 JOIN products USING(product_id)
 JOIN customers USING(customer_id)
INNER JOIN
 (SELECT 
	meal_name FROM products 
	JOIN purchases USING(product_id)
	GROUP BY 
	product_id, meal_name
	ORDER BY 
	SUM(quantity * price) DESC
	LIMIT 3
    ) AS rev
    USING(meal_name)
    WHERE customers.children = 'yes'
    GROUP BY 1;
    
			-- What is the running total of revenue generated by each cuisine over time?
-- Calculate the revenue and partition by cuisine to get a running total by purchase date.
SELECT purchases.purchase_date, products.cuisine, 
       SUM(purchases.quantity * products.price) OVER 
       (PARTITION BY products.cuisine ORDER BY purchases.purchase_date) AS running_total
FROM purchases
JOIN products ON purchases.product_id = products.product_id
ORDER BY products.cuisine, purchases.purchase_date;

			-- Which meal kits are the most popular among customers with children?
-- Calculate quantity sold and group by customers with children.
SELECT products.meal_name, SUM(purchases.quantity) AS quantity FROM products
JOIN purchases USING(product_id)
JOIN customers USING(customer_id)
WHERE customers.children = 'no'
GROUP BY 1
ORDER BY 2 DESC;

			-- What is the percentage of customers who have purchased vegan/vegetarian meals at least once?
-- Count the total number of customers and divide by count of customers who purchases meatless meals.
SELECT  CONCAT(ROUND((COUNT(DISTINCT purchases.customer_id) / (SELECT COUNT(*) FROM customers)) * 100, 2), '%') AS percentage
FROM purchases
JOIN products USING(product_id)
WHERE meatless = 'yes';

			-- Which cuisine generates the most revenue?
-- Calaculate the revenue and group by cuisine. Limit to 1 to determine highest revenue
SELECT products.cuisine, SUM(products.price * purchases.quantity) AS revenue FROM products
JOIN purchases USING(product_id)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

			-- What is the total revenue for each month of the year in 2023?
-- 
SELECT MONTH(purchase_date) AS 'month', ROUND(SUM(purchases.quantity * products.price), 2) AS revenue FROM purchases
JOIN products USING(product_id)
WHERE purchase_date LIKE '%2023%'
GROUP BY 1
ORDER BY 1;

			-- What is the average number of days between a customer's first purchase and second purchase?
WITH days AS (

SELECT customer_id,
       DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY purchase_date) AS purchase_num,
       purchase_date,
       LAG(purchase_date) OVER (PARTITION BY customer_id ORDER BY purchase_date) AS prev_date,
       DATEDIFF(purchase_date, LAG(purchase_date) OVER (PARTITION BY customer_id ORDER BY purchase_date)) AS days_between
FROM purchases
ORDER BY customer_id, purchase_date)
SELECT AVG(days_between) AS average_days FROM days
WHERE purchase_num = 2;










