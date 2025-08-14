CREATE DATABASE RETAIL_INTERSHIP

---------- ====================== PRODUCTS INFO TABLE ======================== ----------
SELECT * FROM ProductsInfo
WHERE Category = '#N/A'

UPDATE ProductsInfo
SET Category = 'Unknown'
WHERE Category = '#N/A'

select product_name_lenght,product_description_lenght,product_photos_qty from ProductsInfo
where product_name_lenght IS NULL or product_description_lenght IS NULL or product_photos_qty IS NULL

-- Step 1: Declare the variable
-- Declare the variable
DECLARE @mean_product_name_lenght INT

-- Assign the mean value
SELECT @mean_product_name_lenght = AVG(TRY_CAST(product_name_lenght AS INT))
FROM ProductsInfo
WHERE TRY_CAST(product_name_lenght AS INT) IS NOT NULL

-- Update NULL values with the calculated mean
UPDATE ProductsInfo
SET product_name_lenght = CAST(@mean_product_name_lenght AS VARCHAR)
WHERE product_name_lenght IS NULL



UPDATE ProductsInfo
SET product_name_lenght = CAST(CAST(TRY_CAST(product_name_lenght AS FLOAT) AS INT) AS VARCHAR)
WHERE TRY_CAST(product_name_lenght AS FLOAT) IS NOT NULL

------------ Product phot quantity -------------
DECLARE @mean_photos INT

SELECT @mean_photos = CAST(AVG(TRY_CAST(product_photos_qty AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_photos_qty AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_photos_qty = CAST(@mean_photos AS VARCHAR)
WHERE product_photos_qty IS NULL

-------------- Product description name length ----------

DECLARE @mean_desc INT

SELECT @mean_desc = CAST(AVG(TRY_CAST(product_description_lenght AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_description_lenght AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_description_lenght = CAST(@mean_desc AS VARCHAR)
WHERE product_description_lenght IS NULL




------- Product Hieght cm ------
DECLARE @mean_height INT

SELECT @mean_height = CAST(AVG(TRY_CAST(product_height_cm AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_height_cm AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_height_cm = CAST(@mean_height AS VARCHAR)
WHERE product_height_cm IS NULL



------- Product width cm -------

DECLARE @mean_width INT

SELECT @mean_width = CAST(AVG(TRY_CAST(product_width_cm AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_width_cm AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_width_cm = CAST(@mean_width AS VARCHAR)
WHERE product_width_cm IS NULL

SELECT * FROM ProductsInfo
WHERE Category = 'Unknown'

------ product category baby --------
SELECT * FROM ProductsInfo
WHERE Category = 'Baby' and product_weight_g = 0

----
DELETE FROM ProductsInfo
WHERE Category = 'Baby' AND TRY_CAST(product_weight_g AS FLOAT) = 0

-- 
SELECT * FROM ProductsInfo
WHERE Category = 'Baby' and product_weight_g is null and product_length_cm is null

--
DECLARE @mean_length INT

SELECT @mean_length = CAST(AVG(TRY_CAST(product_length_cm AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_length_cm AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_length_cm = CAST(@mean_length AS VARCHAR)
WHERE product_length_cm IS NULL

--
DECLARE @mean_weight INT

SELECT @mean_weight = CAST(AVG(TRY_CAST(product_weight_g AS FLOAT)) AS INT)
FROM ProductsInfo
WHERE TRY_CAST(product_weight_g AS FLOAT) IS NOT NULL

UPDATE ProductsInfo
SET product_weight_g = CAST(@mean_weight AS VARCHAR)
WHERE product_weight_g IS NULL





------------------ ========= ORDER TABLE ============== --------------------

WITH RepeatedCustomerStore AS (
    SELECT Customer_id, Delivered_StoreID
    FROM ORDERS
    GROUP BY Customer_id, Delivered_StoreID
    HAVING COUNT(*) > 1
)

SELECT o.*
FROM ORDERS o
JOIN RepeatedCustomerStore r
  ON o.Customer_id = r.Customer_id
 AND o.Delivered_StoreID = r.Delivered_StoreID
ORDER BY o.Customer_id, o.Delivered_StoreID
---------------






----------------- Dropping the entire dupicated row in stores table -------------

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY StoreID, seller_city, seller_state, Region
               ORDER BY (SELECT NULL)
           ) AS Duplicates_store
    FROM StoresInfo
)
DELETE FROM CTE
WHERE Duplicates_store > 1

----------- Dropping duplicates form order review table ------------
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, Customer_Satisfaction_Score
               ORDER BY (SELECT NULL)
           ) AS Duplicates_review
    FROM OrderReview_Ratings
)
DELETE FROM CTE
WHERE Duplicates_review > 1

----------------------- Deleting the duplicates in Order Payments Table --------------
WITH RankedPayments AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, payment_type, payment_value
               ORDER BY (SELECT NULL)
           ) AS Duplicate_pyments
    FROM OrderPayments
)
DELETE FROM RankedPayments
WHERE Duplicate_pyments > 1


WITH RepeatedOrderProduct AS (
    SELECT order_id, product_id
    FROM ORDERS
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
)

SELECT o.*
FROM ORDERS o
JOIN RepeatedOrderProduct r
  ON o.order_id = r.order_id
 AND o.product_id = r.product_id
ORDER BY o.order_id, o.product_id


SELECT COUNT(*) AS count_entire_row_duplicates FROM 
(
	SELECT *, COUNT(*) AS duplicate_count
	FROM OrderReview_Ratings
	GROUP BY order_id, Customer_Satisfaction_Score
	HAVING COUNT(*) > 1
) AS A

SELECT *
	FROM OrderReview_Ratings
	where order_id = '0749426d1c48fe5943cbdf1316ace0aa'
	GROUP BY order_id, Customer_Satisfaction_Score
	

------
ALTER TABLE ORDERS
ADD Clean_Bill_date_timestamp Varchar(25)

UPDATE Orders
SET Clean_Bill_date_timestamp = 
    CONVERT(VARCHAR, TRY_CAST(Bill_date_timestamp AS DATETIME), 105)

---
WITH RankedOrders AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY Customer_id, order_id, Bill_date_timestamp, Channel
               ORDER BY Quantity DESC
           ) AS repatative_order
    FROM Orders
)
-- Select only the top row (max quantity) for each duplicate group
SELECT *
FROM RankedOrders
WHERE repatative_order = 1

DELETE FROM Orders
WHERE TRY_CAST(Bill_date_timestamp AS DATETIME) NOT BETWEEN '2021-09-01' AND '2023-10-31'

----------------------------
WITH RankedOrders AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id, product_id
               ORDER BY TRY_CAST(Quantity AS INT) DESC
           ) AS rank
    FROM Orders
)

DELETE FROM RankedOrders
WHERE rank > 1

----------------------------------------------
SELECT COUNT(count_DUPLICATES) AS total_duplicates_order 
FROM(
	SELECT order_id, COUNT(*) AS count_DUPLICATES
	FROM Orders
	GROUP BY order_id
	HAVING COUNT(*) > 1
) AS A

--- cleaning the order id in orders table ---
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id) AS duplicates_order
    FROM ORDERS
)
DELETE FROM CTE
WHERE duplicates_order > 1

------------ ================= PAYMENT VALUES ================= ------------------
--- 10177---

SELECT * FROM Orders AS O
JOIN OrderPayments AS P
ON O.order_id = P.order_id
WHERE ROUND(P.payment_value,2) != ROUND(O.[Total Amount], 2)

-----    9701 ----------

SELECT O.order_id,O.[Total Amount], P.payment_value, 
    ROUND(P.payment_value - O.[Total Amount], 2) AS AMT_DIFF
FROM Orders AS O
JOIN OrderPayments AS P
    ON O.order_id = P.order_id
WHERE ABS(ROUND(P.payment_value - O.[Total Amount], 2)) > 4

----
DELETE FROM Orders
WHERE order_id IN (
    SELECT O.order_id
    FROM Orders O
    JOIN OrderPayments P ON O.order_id = P.order_id
    WHERE ROUND(O.[Total Amount], 2) != ROUND(P.payment_value, 2)
)


SELECT * FROM Orders AS O
JOIN Customers AS C
ON C.Custid = O.Customer_id
JOIN OrderPayments AS OP
ON OP.order_id = O.order_id
JOIN OrderReview_Ratings AS R
ON R.order_id = O.order_id
JOIN ProductsInfo AS P
ON P.product_id = O.product_id
JOIN StoresInfo AS S
ON S.StoreID = O.Delivered_StoreID
WHERE [Total Amount] = 0