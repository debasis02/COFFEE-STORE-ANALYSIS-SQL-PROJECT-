/*What is the total no. of customers having loyalty card.
(Make two column for Yes and No respectively with count of loyalty card in 1st row)*/
SELECT 
    COUNT(CASE WHEN Loyalty_Card='Yes' THEN Customer_ID END) AS YES,
    COUNT(CASE WHEN Loyalty_Card='No' THEN Customer_ID END) AS NO
FROM customers;


/*Change the datatype of Order_Date from char to date.*/
UPDATE coffee.order
SET Order_Date = STR_TO_DATE(Order_Date, '%d-%m-%Y');


/*How Many quantity of coffee sold between 14-08-2019 and 25-04-2020?*/
select sum(quantity) as Total from coffee.order
where Order_Date between '2019-06-14' and '2020-01-20';


/*Print no. of sales Yearwise.*/
SELECT SUM(quantity) AS Total, YEAR(Order_Date) AS Year 
FROM coffee.order 
GROUP BY Year 
ORDER BY Year;


/*Which customer ordered the most quantity of products?*/
SELECT SUM(o.quantity) AS Total, c.customer_name AS Name
FROM coffee.order o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY Name
ORDER BY Total DESC LIMIT 1;


/*Print no. of sales monthwise(rowwise) with Years as column.*/
SELECT MONTH(Order_Date) as Month,
    COUNT(CASE WHEN YEAR(Order_Date) = '2019' THEN MONTH(Order_Date) END) as '2019',
    COUNT(CASE WHEN YEAR(Order_Date) = '2020' THEN MONTH(Order_Date) END) as '2020',
    COUNT(CASE WHEN YEAR(Order_Date) = '2021' THEN MONTH(Order_Date) END) as '2021',
    COUNT(CASE WHEN YEAR(Order_Date) = '2022' THEN MONTH(Order_Date) END) as '2022'
FROM coffee.order
GROUP BY Month
ORDER BY Month;


/*Which Country has the most Loyal customers to total customer by percentage.*/
SELECT Country, 
ROUND(COUNT(CASE WHEN Loyalty_Card='Yes' THEN Customer_ID END)*100/COUNT(Customer_ID), 2) AS LoyalPercentage
FROM customers
GROUP BY Country;


/*Write profits over month for each year and Average profit over months.*/
WITH cte AS (
    SELECT MONTH(Order_Date) AS Month,
           SUM(CASE WHEN YEAR(Order_Date) = '2019' THEN o.Quantity * p.Unit_Price END) AS Year2019,
           SUM(CASE WHEN YEAR(Order_Date) = '2020' THEN o.Quantity * p.Unit_Price END) AS Year2020,
           SUM(CASE WHEN YEAR(Order_Date) = '2021' THEN o.Quantity * p.Unit_Price END) AS Year2021,
           SUM(CASE WHEN YEAR(Order_Date) = '2022' THEN o.Quantity * p.Unit_Price END) AS Year2022
    FROM coffee.order o
    JOIN profit p ON o.product_id = p.product_id
    GROUP BY MONTH(Order_Date)
)
SELECT cte.Month,
       ROUND(SUM(Year2019) OVER (ORDER BY cte.Month),2) AS Year2019,
       ROUND(SUM(Year2020) OVER (ORDER BY cte.Month),2) AS Year2020,
       ROUND(SUM(Year2021) OVER (ORDER BY cte.Month),2) AS Year2021,
       ROUND(SUM(Year2022) OVER (ORDER BY cte.Month),2) AS Year2022,
       ROUND((CASE WHEN Year2022=0 THEN (Year2019+Year2020+Year2021+Year2022)/4
			  ELSE (Year2019+Year2020+Year2021)/3 END),2) AS Avg
FROM cte;


/*write the name of the top 10 customer who spent the most money?(round off to 2 decimal places)*/
SELECT c.Customer_Name, ROUND(SUM(o.Quantity * p.Unit_Price), 2) AS Total 
FROM customers c 
JOIN coffee.order o ON c.customer_id = o.customer_id 
JOIN profit p ON o.product_id = p.product_id 
GROUP BY c.Customer_Name 
ORDER BY Total DESC 
LIMIT 10;


/*How many customers are there where city name ends with Junction.*/
SELECT COUNT(customer_id) AS COUNT 
FROM customers 
WHERE RIGHT(Address_Line1, 8) = 'Junction';


/*What is name of the top 3 customers with most quantities ordered?(customer with same orders will have same rank)*/
SELECT *
FROM (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY Total DESC) AS rank_no
    FROM (
        SELECT SUM(o.quantity) AS Total, c.customer_name AS Name
        FROM coffee.order o
        JOIN customers c ON c.customer_id = o.customer_id
        GROUP BY Name
        ORDER BY Total DESC
    ) AS t
) AS ranked
WHERE rank_no <= 3;


/*Write top 3 product for each coffee type according to profit?*/
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Coffee_Type ORDER BY Profit DESC) AS rank_no
    FROM (
        SELECT t.Product_ID AS Product_ID, t.coffee_type AS Coffee_Type, p.profit AS Profit
        FROM type t
        JOIN profit p ON t.Product_ID = p.Product_ID
        ORDER BY t.Coffee_Type, p.Profit DESC
    ) AS subquery
) AS ranked
WHERE rank_no < 4;


/*Write cummulative profits over the months for year 2020.*/
WITH cte AS (
    SELECT MONTH(Order_Date) AS Month,
           SUM(CASE WHEN YEAR(Order_Date) = '2020' THEN o.Quantity * p.Unit_Price END) AS Year2020
    FROM coffee.order o
    JOIN profit p ON o.product_id = p.product_id
    GROUP BY MONTH(Order_Date)
)
SELECT cte.Month,
       ROUND(SUM(CTE.Year2020) OVER (ORDER BY cte.Month),2) AS CumulativeProfit
FROM cte;


/*What is the top 3 City giving maximum profit for each country.*/
WITH CTE AS (
    SELECT ROUND(SUM(o.Quantity * p.Unit_Price), 2) AS Total, c.Country, c.City
    FROM customers c
    JOIN coffee.order o ON c.customer_id = o.customer_id
    JOIN profit p ON o.product_id = p.product_id
    GROUP BY c.Country, c.City),
CTE2 AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Total DESC) AS r
    FROM CTE)
SELECT *
FROM CTE2
WHERE r <= 3;


/*Write the name of the third highest customer who spent the most money?(round off to 2 decimal places)
(Query should not include limit and window functions)*/
/*METHOD 1 */
WITH CTE AS (
    SELECT c.Customer_Name, ROUND(SUM(o.Quantity * p.Unit_Price), 2) AS Total
    FROM customers c
    JOIN coffee.order o ON c.customer_id = o.customer_id
    JOIN profit p ON o.product_id = p.product_id
    GROUP BY c.Customer_Name
)
SELECT Total as Third_Highest, Customer_Name 
FROM CTE
WHERE Total = (
    SELECT MAX(Total)
    FROM CTE
    WHERE Total < (
        SELECT MAX(Total)
        FROM CTE
        WHERE Total < (SELECT MAX(Total)
					   FROM CTE)
    )
);
/*	METHOD 2 */
WITH CTE AS (
    SELECT c.Customer_Name as Customer_Name, ROUND(SUM(o.Quantity * p.Unit_Price), 2) AS Total
    FROM customers c
    JOIN coffee.order o ON c.customer_id = o.customer_id
    JOIN profit p ON o.product_id = p.product_id
    GROUP BY c.Customer_Name
)
SELECT DISTINCT(Total),Customer_Name
FROM CTE c1
WHERE 3 = (SELECT COUNT(DISTINCT Total)
           FROM CTE c2
           WHERE c1.Total <= c2.Total);


/*Write the name of the customer who order in two consecutive days.*/
WITH cte AS (
    SELECT o1.Customer_id, o2.Order_Date AS Order_Date1, o1.Order_Date AS Order_Date2
    FROM coffee.order o1
    JOIN coffee.order o2
    ON DATEDIFF(o1.Order_Date, o2.Order_Date) = 1 AND o1.Customer_id = o2.Customer_id
)
SELECT c1.customer_name, c.Order_Date1, c.Order_Date2
FROM customers c1
JOIN cte c
ON c1.Customer_ID = c.Customer_id;


/*Who are the longest customers of the coffee store?*/
WITH cte AS (
    SELECT MAX(Order_Date) - MIN(Order_Date) AS diff, Customer_ID 
    FROM coffee.order
    GROUP BY Customer_ID
)
SELECT c.Customer_Name, c1.diff 
FROM customers c
RIGHT JOIN cte c1
ON c.Customer_ID = c1.Customer_ID
WHERE c1.diff = (SELECT MAX(diff) FROM cte);


/*Name an interval of 10 days (difference between start date and end date is 10) in which maximum orders have been received.*/
WITH cte AS (
    SELECT DISTINCT
        order_date AS start_date, DATE_ADD(order_date, INTERVAL 10 DAY) AS end_date
    FROM coffee.order
)
SELECT
    COUNT(o.order_id) AS MAX, c.start_date, c.end_date
FROM coffee.order o
LEFT JOIN cte c ON o.order_date BETWEEN c.start_date AND c.end_date
GROUP BY c.start_date, c.end_date
ORDER BY MAX DESC LIMIT 5;