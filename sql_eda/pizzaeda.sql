-- - We have the data of maven pizza for Year 2015.
-- - What days and times do we tend to be busiest?
-- - How many pizzas are we making during peak periods? 
-- - What are our best and worst selling pizzas? 
-- - What's our average order value? 
-- - How well are we utilizing our seating capacity? (we have 15 tables and 60 seats)



-- ---------------------------------------------------------------------------------------------------------------
USE mavenpizza;

-- find null values
-- order_details
SELECT * FROM order_details
WHERE order_details_id IS NULL OR order_id IS NULL OR pizza_id IS NULL OR Quantity IS NULL;
-- orders
SELECT * FROM orders
WHERE order_id IS NULL OR date IS NULL OR time IS NULL;
-- pizza types 
SELECT * FROM pizza_types
WHERE pizza_type_id IS NULL OR name IS NULL OR category IS NULL OR ingredients IS NULL;
-- pizzas
SELECT * FROM pizzas
WHERE pizza_id IS NULL OR pizza_type_id IS NULL OR size IS NULL OR price IS NULL;
-- there are no null values in my dataset
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- PEAK TIME ANALYSIS
-- What days and time do we tend to be busiest?
SELECT * FROM orders;

ALTER TABLE orders
ADD COLUMN day VARCHAR(10),
ADD COLUMN month VARCHAR(15);
UPDATE orders
SET day = dayname(date), month = monthname(date);

SELECT day, COUNT(order_id) order_counts_of_day
FROM orders
GROUP BY day
ORDER BY order_counts_of_day DESC;
-- Friday has maximum number of orders in 2015 - 3538 followed by Thursday - 3239 and Saturday - 3158 

WITH temp_table AS (SELECT
    *,
    CASE
        WHEN HOUR(`time`) >= 0 AND HOUR(`time`) <= 10 THEN CONCAT(HOUR(`time`), 'AM - ', (HOUR(`time`)+1), 'AM')
        WHEN HOUR(`time`) = 11 THEN CONCAT(HOUR(`time`), 'AM - ', (HOUR(`time`)+1), 'PM')
        WHEN HOUR(`time`) = 12 THEN CONCAT(HOUR(`time`), 'PM - ', 1, 'PM')
        WHEN HOUR(`time`) > 12 and HOUR(`time`) <=22 THEN CONCAT((HOUR(`time`)-12), 'PM - ', (HOUR(`time`)-11), 'PM')
        WHEN HOUR(`time`) = 23  THEN CONCAT((HOUR(`time`)-12), 'PM - ', (HOUR(`time`)-11), 'AM')
    END AS hour_of_day
FROM orders)

SELECT hour_of_day, COUNT(order_id) order_counts_in_hour_of_day
FROM temp_table
GROUP BY hour_of_day
ORDER BY order_counts_in_hour_of_day DESC;
-- busiest time of day are 12PM-1PM
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- PIZZA PER DAY, PER HOUR ANALYSIS
WITH pizza_quantity_on_a_date AS (SELECT date, SUM(quantity) AS number_of_pizzas
FROM orders
JOIN order_details
ON orders.order_id = order_details.order_id
GROUP BY date)

SELECT MIN(number_of_pizzas) AS minimum_no_of_pizzas, 
MAX(number_of_pizzas) AS maximum_no_of_pizzas, ROUND(AVG(number_of_pizzas),0) AS average_no_of_pizzas
FROM pizza_quantity_on_a_date;
-- range between 77-266 pizzas and having a average of 138 pizzas per day

WITH temp_table AS (SELECT date, HOUR(time) AS hour, SUM(quantity) quantity
FROM orders
JOIN order_details
ON orders.order_id = order_details.order_id
GROUP BY date, HOUR(time))

SELECT MIN(avg_Quantity_in_a_hour), MAX(avg_Quantity_in_a_hour), ROUND(AVG(avg_Quantity_in_a_hour),0)
FROM (SELECT hour, ROUND(AVG(quantity), 0) avg_Quantity_in_a_hour
FROM temp_table
GROUP BY hour) AS t1;
-- range between 2-19 pizzas and having a average of 10 pizzas per hour
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- BEST AND WORST SELLING PIZZAS
-- best selling pizza
SELECT name, SUM(quantity) total_quantity_sold
FROM order_details o1
JOIN pizzas p1
ON o1.pizza_id = p1.pizza_id
JOIN pizza_types p2
ON p1.pizza_type_id = p2.pizza_type_id
GROUP BY name
ORDER BY total_quantity_sold DESC LIMIT 1;
-- worst selling pizza 
SELECT name, SUM(quantity) total_quantity_sold
FROM order_details o1
JOIN pizzas p1
ON o1.pizza_id = p1.pizza_id
JOIN pizza_types p2
ON p1.pizza_type_id = p2.pizza_type_id
GROUP BY name
ORDER BY total_quantity_sold ASC LIMIT 1;
-- `The Barbeque Chicken Pizza` is the best selling pizza - 1411 (total quantity sold in 2015) 
-- `The Brie Carre Pizza` is the worst selling pizza - 277 (total quantity sold in 2015)
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- AVERAGE ORDER VALUE 
WITH temp_table AS (SELECT order_id, quantity*price AS order_value
FROM order_details 
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id)

SELECT ROUND(AVG(order_value),2) average_order_value FROM (SELECT order_id, SUM(order_value) AS order_value 
FROM temp_table
GROUP BY order_id) AS t1;
-- average order value is $38.28
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- UTILISATION OF SEATING CAPACITY
-- (we have 15 tables and 60 seats)
-- average order per hour
SELECT ROUND(AVG(avg_orders),0) FROM (
SELECT hour, AVG(total_orders) AS avg_orders 
FROM (
SELECT date, HOUR(time) AS hour, COUNT(order_id) AS total_orders
FROM orders
GROUP BY HOUR(time), date
) t1
GROUP BY hour) t2;
-- every hour 4 orders are placed on every day
-- if we consider that each order take 1 table, then 4 tables are occupied every hour. Therefore our table filled 
-- percentage is nearly 26-27 %
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- TOTAL ORDERS IN 2015
SELECT COUNT(order_id) FROM orders;
-- total orders placed in 2015 are 21350
-- TOTAL PIZZA SOLD IN 2015
SELECT SUM(quantity) AS total_pizzas FROM order_details;
-- total pizza sold in 2015 are 27874
-- TOTAL SALES AMOUNT IN 2015
SELECT ROUND(SUM(quantity*price),2) AS `Total Sales`
FROM order_details 
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id;
-- total sales is 460689.7
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- average quantity sold a week day
WITH temp_table AS (SELECT date, day, SUM(quantity) AS quantity FROM orders
JOIN order_details
ON orders.order_id = order_details.order_id
GROUP BY date, day)

SELECT day, ROUND(AVG(quantity),0) avg_quantity FROM temp_table
GROUP BY day
ORDER BY avg_quantity ASC;
-- insights: least quantity of pizza sale is on sunday. So sales has to be improved on sunday
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- WHICH MONTH BRINGS OUT MOST SALES
SELECT month, ROUND(SUM(quantity*price),2) as `Total Sales` FROM order_details
JOIN pizzas
ON order_details.pizza_id = pizzas.pizza_id
JOIN orders
ON orders.order_id = order_details.order_id
GROUP BY month
ORDER BY `Total Sales` DESC;
-- Maximum number of sales is in May and least number of sales is in july
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- SALES BY SIZE
SELECT size, COUNT(order_id) total_orders FROM order_details o1
JOIN pizzas p1
ON o1.pizza_id = p1.pizza_id
GROUP BY size 
ORDER BY total_orders DESC;
-- 10478 orders contain large size pizza. 
-- Nearly 38% customers prefer large size pizza
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- TOP 5 PIZZAS BY REVENUE
SELECT name, ROUND(SUM(quantity*price),2) AS total_sales FROM order_details o1
JOIN pizzas p1
ON o1.pizza_id = p1.pizza_id
JOIN pizza_types p2
ON p1.pizza_type_id = p2.pizza_type_id
GROUP BY name
ORDER BY total_sales DESC LIMIT 5;
-- ---------------------------------------------------------------------------------------------------------------



-- ---------------------------------------------------------------------------------------------------------------
-- TOTAL OREDRS BY CATEGORY
SELECT category, COUNT(order_id) FROM order_details o1
JOIN pizzas p1
ON o1.pizza_id = p1.pizza_id
JOIN pizza_types p2
ON p1.pizza_type_id = p2.pizza_type_id
GROUP BY category; 
-- 30% PERCENT OF customers prefer Classicflights

