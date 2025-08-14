
SELECT * FROM CUSTOMER360

---- ==== THE NUMBER OF ORDERS ==== ----

SELECT COUNT(order_id) NUMBER_ORDERS FROM ORDER360

---- ==== TOTAL DISCOUNT ==== ----

SELECT SUM(Discount) TOTAL_DISCOUNT FROM ORDER360

---- ==== AVERAGE DISCOUNT PER CUSTOMER ==== ----

SELECT AVG(TOTAL_DISCOUNT) AVG_DISCOUNT_PER_CUSTOMER FROM CUSTOMER360
WHERE Custid IN (SELECT DISTINCT(Custid) FROM CUSTOMER360)

---- ==== AVERAGE DISCOUNT PER ORDER ==== ----

SELECT AVG(Discount) AVG_DISCOUNT_PER_ORDER FROM ORDER360
WHERE order_id IN (SELECT DISTINCT(ORDER_ID) FROM ORDER360)

---- ==== Average order value or Average Bill Value ==== ----

SELECT AVG(TOTAL_AMOUNT_SPENT) AS AVG_ORER_VALUE FROM ORDER360

---- ==== Average Sales per Customer ==== ----

SELECT AVG(TOTAL_AMOUNT_SPENT) AS AVG_SALES_PER_CUSTOMER FROM CUSTOMER360
WHERE Custid IN (SELECT DISTINCT(Custid) FROM CUSTOMER360)

---- ==== AVERAGE PROFIT PER CUSTOMER ==== ----

SELECT AVG(TOTAL_PROFIT) FROM CUSTOMER360
WHERE Custid IN (SELECT DISTINCT(Custid) FROM CUSTOMER360)

---- ==== AVERAGE NUMBER OF CATEGRIES PER ORDER ==== ----

SELECT (COUNT(Category))/COUNT(DISTINCT(order_id)) AVG_CATE_PER_ORDER FROM ORDER360

---- ==== NUMBER OF CUSTOMER ==== ----

SELECT COUNT(DISTINCT Custid) NUMBER_OF_CUSTOMER FROM CUSTOMER360

---- ==== TRANSACTIONS_PER_CUSTOMER ==== ----

SELECT AVG(No_of_Transaction) AS AVG_TRANSACTION_PER_CUST FROM CUSTOMER360

---- ==== TOTAL REVENUE ==== ----

SELECT SUM(TOTAL_AMOUNT_SPENT) REVENUE FROM ORDER360

---- ==== TOTAL PROFIT ==== ----

SELECT SUM(TOTAL_PROFIT) TOTAL_PROFIT FROM ORDER360

---- ==== TOTAL COST ==== ----

SELECT SUM([Cost Per Unit]) AS TOTAL_COST FROM ORDER360

---- ==== TOTAL QUANTITY ==== ----

SELECT SUM(QUANTITY) TOTAL_QUANTITY FROM ORDER360

---- ==== TOTAL PRODUCTS ==== ----
SELECT COUNT(DISTINCT product_id) AS COUNT_PRODUCT FROM ORDER360

---- ==== TOTAL CATEGORIES ==== ----

SELECT COUNT(DISTINCT Category) AS COUNT_CATEGORY FROM ORDER360

---- ==== TOTAL STORES ==== -----

SELECT COUNT(DISTINCT Delivered_StoreID) AS STORE_ID FROM ORDER360

---- ==== Total locations ==== ----

SELECT COUNT(DISTINCT seller_city) LOCATION_BY_STORE FROM STORE360

SELECT COUNT(DISTINCT customer_city) LOCATION_BY_CUSTOMER FROM CUSTOMER360

---- ==== TOTAL REGIONS ==== ----

SELECT COUNT(DISTINCT Region) AS TOTAL_REGION FROM STORE360



---- ==== TOTAL CHANNELS ==== ----

SELECT COUNT(DISTINCT Channel) AS TOTAL_CHANNEL FROM ORDER360

---- ==== TOTAL PAYMENT METHODS ==== ----

SELECT COUNT(DISTINCT payment_type) AS TOTAL_PAYMENT_METHODS FROM ORDER360

---- ==== Average number of days between two transactions (if the customer has more than one transaction) ==== ----

SELECT AVG(DAYS_DIFF) AS AVERAGE_NUMBER_BETWEEN_TWO_TRANSACTION 
FROM(
		SELECT *,(DATEDIFF(DAY, min_date, max_date)) AS DAYS_DIFF 
		FROM(
						select Customer_id,
							min(try_cast(Bill_date_timestamp as date)) as min_date, 
							max(try_cast(Bill_date_timestamp as date)) as max_date	
						from ORDER360
						
						group by Customer_id
						Having min(Bill_date_timestamp) != max(Bill_date_timestamp)
		) AS A
) AS B

---- ==== PERCENTAGE OF PROFIT ==== -----

SELECT ROUND(((SUM(TOTAL_PROFIT)/SUM(TOTAL_AMOUNT_SPENT)) * 100),2) AS PERCENTAGE_OF_PROFIT FROM ORDER360

SELECT SUM(TOTAL_PROFIT)/((SUM(([Cost Per Unit] -DISCOUNT) * Quantity))) * 100 AS PERCENTAGE_OF_PROFIT FROM ORDER360

---- ==== PERCENTAGE DISCOUNT ==== ----

SELECT SUM(TOTAL_DISCOUNT)/SUM(TOTAL_AMOUNT_SPENT) * 100 AS DISCOUNT_PERCENTAGE FROM ORDER360

---- ==== REPEAT PURCHASE RATE ==== ----
select * from ORDER360

SELECT 
    (COUNT(REPEAT_purchase) * 100.0) / 
     (SELECT sum(TOTAL_QUANTITY) FROM ORDER360) AS Repeat_Purchase_Rate
FROM (
    SELECT sum(Quantity) AS REPEAT_purchase
    FROM ORDER360
    GROUP BY Customer_id
    HAVING COUNT(DISTINCT order_id) > 1
) AS Repeat_Customers



---- ==== REPEAT CUSTOMER PERCENTAGE ==== ----

SELECT (COUNT(REPEAT_CUSTOMER) * 1.0 / (SELECT COUNT(DISTINCT Customer_id) FROM ORDER360)) * 100 AS REPAT_CUST_PER
		FROM(
						select Customer_id AS REPEAT_CUSTOMER,
							min(try_cast(Bill_date_timestamp as date)) as min_date, 
							max(try_cast(Bill_date_timestamp as date)) as max_date	
						from ORDER360
						
						group by Customer_id
						Having min(Bill_date_timestamp) != max(Bill_date_timestamp)
		) AS A

----- ==== ONE TIME BUYER PERCENTAGE ==== ----

SELECT (COUNT(ONE_TIME_BUYER_CUSTOMER) * 1.0 / (SELECT COUNT(DISTINCT Customer_id) FROM ORDER360)) * 100 AS REPAT_CUST_PER
		FROM(
						select Customer_id AS ONE_TIME_BUYER_CUSTOMER,
							min(try_cast(Bill_date_timestamp as date)) as min_date, 
							max(try_cast(Bill_date_timestamp as date)) as max_date	
						from ORDER360
						
						group by Customer_id
						Having min(Bill_date_timestamp) = max(Bill_date_timestamp)
		) AS A




---- ==== new customers acquired every month ==== ----


SELECT 
    First_Purchase_Month,
    COUNT(*) AS New_Customers
FROM (
    SELECT 
        Customer_id,
        FORMAT(MIN(CAST(Bill_date_timestamp AS DATE)), 'yyyy-MM') AS First_Purchase_Month
    FROM ORDER360
    GROUP BY Customer_id
) AS FirstOrders
GROUP BY First_Purchase_Month
ORDER BY First_Purchase_Month

---- ==== Top 10 products ---
WITH ProductSales AS (
    SELECT 
        product_id,
        MAX(MRP) AS Unit_Price,
        SUM([Total Amount]) AS Total_Sales
    FROM ORDER360
    GROUP BY product_id
),

TotalSales AS (
    SELECT SUM([Total Amount]) AS Overall_Sales
    FROM ORDER360
)

SELECT TOP 10 
    PS.product_id,
    PS.Unit_Price,
    PS.Total_Sales,
    ROUND((PS.Total_Sales / TS.Overall_Sales) * 100, 2) AS Sales_Contribution_Percentage
FROM ProductSales PS
CROSS JOIN TotalSales TS
ORDER BY PS.Unit_Price DESC

----- ===== Understand the retention of customers on month on month basis ===== -----
 

WITH Monthly_Customers AS (
    SELECT 
        Customer_id,
        FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS YearMonth
    FROM ORDER360
    GROUP BY Customer_id, FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM')
),
Customer_Retention AS (
    SELECT 
        curr.YearMonth AS Current_Month,
        COUNT(DISTINCT curr.Customer_id) AS Total_Customers,
        COUNT(DISTINCT prev.Customer_id) AS Retained_Customers
    FROM Monthly_Customers curr
    LEFT JOIN Monthly_Customers prev
        ON curr.Customer_id = prev.Customer_id
        AND DATEADD(MONTH, -1, CAST(curr.YearMonth + '-01' AS DATE)) = CAST(prev.YearMonth + '-01' AS DATE)
    GROUP BY curr.YearMonth
)
SELECT 
    Current_Month,
    Total_Customers,
    Retained_Customers,
    (CAST(Retained_Customers AS FLOAT) / NULLIF(Total_Customers, 0)) * 100 AS Retention_Rate_Percentage
FROM Customer_Retention
ORDER BY Current_Month

----- ====== How the revenues from existing/new customers on monthly basis ====== -------

WITH Customer_First_Purchase AS (
    SELECT 
        Customer_id,
        MIN(TRY_CAST(Bill_date_timestamp AS DATE)) AS First_Purchase_Date
    FROM ORDER360
    GROUP BY Customer_id
),
Order_Cleaned AS (
    SELECT 
        Customer_id,
        TRY_CAST(Bill_date_timestamp AS DATE) AS Order_Date,
        [Total Amount]
    FROM ORDER360
    WHERE ISDATE(Bill_date_timestamp) = 1
),
Order_With_Type AS (
    SELECT 
        O.Customer_id,
        O.[Total Amount],
        FORMAT(O.Order_Date, 'yyyy-MM') AS Order_Month,
        CASE 
            WHEN F.First_Purchase_Date = O.Order_Date
                 OR FORMAT(F.First_Purchase_Date, 'yyyy-MM') = FORMAT(O.Order_Date, 'yyyy-MM')
            THEN 'New'
            ELSE 'Existing'
        END AS Customer_Type
    FROM Order_Cleaned O
    JOIN Customer_First_Purchase F 
      ON O.Customer_id = F.Customer_id
)
SELECT 
    Order_Month,
    Customer_Type,
    SUM([Total Amount]) AS Revenue
FROM Order_With_Type
GROUP BY Order_Month, Customer_Type
ORDER BY Order_Month, Customer_Type;


------- ======= Understand the trends/seasonality of sales, quantity by category, region, store, channel, payment method etc ======= ---------------

SELECT FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS Month,Category,
		Region,
		Delivered_StoreID,
		Channel,
		payment_type,
		SUM([Total Amount] ) AS Total_Sales,
		SUM(Quantity) AS Total_Quantity
FROM ORDER360
GROUP BY FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM'),Category,Region,Delivered_StoreID,Channel,payment_type
ORDER BY Month, Total_Sales desc



SELECT *
FROM (
    SELECT 
        FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS Month,
        Category,
        Region,
        Delivered_StoreID,
        Channel,
        payment_type,
        SUM([Total Amount]) AS Total_Sales,
        SUM(Quantity) AS Total_Quantity,
        ROW_NUMBER() OVER (
            PARTITION BY FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM')
            ORDER BY SUM([Total Amount]) DESC
        ) AS rn
    FROM ORDER360
    WHERE ISDATE(Bill_date_timestamp) = 1
    GROUP BY 
        FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM'),
        Category,
        Region,
        Delivered_StoreID,
        Channel,
        payment_type
) AS Ranked
WHERE rn = 1
ORDER BY Month;

------ ====== 

---- ===== Popular categories/Popular Products by store, state, region ===== -----



SELECT * FROM (
    SELECT StoreID,
        O.Region,
        S.seller_state,
        Category,
        SUM([Total Amount]) AS Total_Sales,
        RANK() OVER (PARTITION BY STOREID, S.SELLER_STATE ORDER BY SUM([Total Amount]) DESC) AS rk
    FROM ORDER360 AS O
	JOIN STORE360 AS S
	ON O.Delivered_StoreID = S.StoreID
    GROUP BY STOREID,O.Region, seller_state, Category
) AS ranked
WHERE rk <= 1

 /*
Understanding how many new customers acquired every month (who made transaction first time in the data)
Understand the retention of customers on month on month basis 
How the revenues from existing/new customers on monthly basis
Understand the trends/seasonality of sales, quantity by category, region, store, channel, payment method etc…
Popular categories/Popular Products by store, state, region. 
List the top 10 most expensive products sorted by price and their contribution to sales
Which products appeared in the transactions?
Top 10-performing & worst 10 performance stores in terms of sales
*/

---- ==== List the top 10 most expensive products sorted by price and their contribution to sales ==== ----

SELECT TOP 10 Category, SALES, ROUND((SALES * 100/(SELECT SUM([Total Amount]) FROM ORDER360)),2) AS PERCENTAGE_SALES FROM(
SELECT DISTINCT(Category),SUM(TOTAL_AMOUNT_SPENT) AS SALES FROM ORDER360
GROUP BY Category
) AS A
ORDER BY PERCENTAGE_SALES DESC

---- ==== TOP 10 BEST PERFORMING STORE ==== ----

SELECT TOP 10 StoreID, SUM(TOTAL_REVENUE) AS SALES FROM STORE360
GROUP BY StoreID
ORDER BY SALES DESC



---- ==== TOP 10 WORST PERFORMING STORE ==== ----

SELECT TOP 10 StoreID, SUM(TOTAL_REVENUE) AS SALES FROM STORE360
GROUP BY StoreID
ORDER BY SALES ASC

/*  
3. Cross-Selling (Which products are selling together) 
Hint: We need to find which of the top 10 combinations of products are selling together in each transaction.  (combination of 2 or 3 buying together) 

4. Understand the Category Behavior
Total Sales & Percentage of sales by category (Perform Pareto Analysis)
Most profitable category and its contribution
Category Penetration Analysis by month on month (Category Penetration = number of orders containing the category/number of orders)
Cross Category Analysis by month on Month (In Every Bill, how many categories shopped. Need to calculate average number of categories shopped in each bill by Region, By State etc)
Most popular category during first purchase of customer
*/

SELECT TOP 10 
    A.Category AS Category_1,
    B.Category AS Category_2,
    COUNT(DISTINCT A.Order_ID) AS Combo_Count
FROM ORDER360 A
JOIN ORDER360 B 
    ON A.Order_ID = B.Order_ID
    AND A.Category < B.Category  -- prevent self-pair and duplicates
GROUP BY A.Category, B.Category
ORDER BY Combo_Count DESC;

---- ======= category behaviour Total Sales & Percentage of sales by category Most profitable category and its contribution ====== ----------

SELECT DISTINCT Category,
				COUNT(Quantity) AS UNITS_SOLD,
				ROUND(SUM([Cost Per Unit]),2) AS MANUFACTURING_COST,
				ROUND(SUM(TOTAL_AMOUNT_SPENT),2) AS REVENUE,
				ROUND(SUM(TOTAL_PROFIT),2) AS NET_PROFIT,
				ROUND(SUM(TOTAL_PROFIT)/SUM(TOTAL_AMOUNT_SPENT),4) *100 AS PROFIT_REVENUE_PER,
				ROUND(SUM(TOTAL_PROFIT)/SUM([Cost Per Unit]),4) *100 AS PROFIT_MANUFACTURING_PER,
				SUM(TOTAL_DISCOUNT * Quantity) AS OVERALL_DISCOUNT,
				ROUND((SUM(TOTAL_DISCOUNT * Quantity)/SUM(TOTAL_PROFIT)),4) * 100 AS DISCOUNT_OVER_PROFIT,
				ROUND((SUM(TOTAL_DISCOUNT * Quantity)/SUM([Cost Per Unit])),4) * 100 AS DISCOUNT_OVER_MANUFACTURIN_COST
FROM ORDER360
GROUP BY Category
ORDER BY NET_PROFIT DESC


SELECT *, (REVENUE * 100 / (SELECT SUM(TOTAL_AMOUNT_SPENT) FROM ORDER360)) AS PERCENTAGE_REV FROM(
SELECT 
    Category,
    ROUND(SUM(TOTAL_AMOUNT_SPENT), 2) AS REVENUE 
FROM ORDER360
GROUP BY Category
) AS A
ORDER BY REVENUE DESC


--------- ====== Most profitable category and its contribution ===== -----

SELECT TOP 1 Category, profits, ROUND((profits * 100/(SELECT SUM(TOTAL_PROFIT) FROM ORDER360)),2) AS PERCENTAGE_PROFITS FROM(
SELECT DISTINCT(Category),SUM(TOTAL_PROFIT) AS profits FROM ORDER360
GROUP BY Category
) AS A
ORDER BY PERCENTAGE_PROFITS DESC

----- ===== Category Penetration Analysis by month on month (Category Penetration = number of orders containing the category/number of orders) ======= -------

SELECT A.Order_Month,
    A.Category,
    A.Orders_With_Category,
    ROUND(A.Orders_With_Category * 1.0 / B.Total_Orders, 4) AS Category_Penetration
FROM
(
    SELECT 
        FORMAT(CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS Order_Month,
        Category,
        COUNT(DISTINCT Order_id) AS Orders_With_Category
    FROM ORDER360
    GROUP BY 
        FORMAT(CAST(Bill_date_timestamp AS DATE), 'yyyy-MM'),
        Category
) AS A
JOIN
(
    SELECT 
        FORMAT(CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS Order_Month,
        COUNT(DISTINCT Order_id) AS Total_Orders
    FROM ORDER360
    GROUP BY FORMAT(CAST(Bill_date_timestamp AS DATE), 'yyyy-MM')
) AS B
ON A.Order_Month = B.Order_Month
ORDER BY A.Order_Month, A.Category

---- ===== 

/* 
5. Customer satisfaction towards category & product 
Which categories (top 10) are maximum rated & minimum rated and average rating score? 
Average rating by location, store, product, category, month, etc.
*/

----------- ======== Which categories (top 10) are maximum rated & minimum rated and average rating score ======= -----------

SELECT TOP 10 cat,RATINGS FROM(
SELECT DISTINCT(Category) as cat , ROUND(AVG(Customer_Satisfaction_Score),2) AS RATINGS FROM ORDER360
GROUP BY Category
) AS A
ORDER BY RATINGS DESC

----------

SELECT TOP 10 cat,RATINGS FROM(
SELECT DISTINCT(Category) as cat , ROUND(AVG(Customer_Satisfaction_Score),2) AS RATINGS FROM ORDER360
GROUP BY Category
) AS A
ORDER BY RATINGS ASC

----- === AVG RATING BY LOCATIONS ==== -----

SELECT DISTINCT (seller_city) CITY, ROUND(AVG(Customer_Satisfaction_Score),2) AS RATINGS FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY seller_city
ORDER BY RATINGS DESC

SELECT DISTINCT (S.StoreID) STORE, ROUND(AVG(Customer_Satisfaction_Score),2) AS RATINGS FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY S.StoreID
ORDER BY RATINGS DESC

SELECT FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM') AS MONTH, ROUND(AVG(Customer_Satisfaction_Score),2) AS RATINGS FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM')
ORDER BY MONTH


/* 
7. Perform analysis related to Sales Trends, patterns, and seasonality. 
"Which months have had the highest sales, what is the sales amount and contribution in percentage?
Which months have had the least sales, what is the sales amount and contribution in percentage?  
Sales trend by month   
Is there any seasonality in the sales (weekdays vs. weekends, months, days of week, weeks etc.)?
Total Sales by Week of the Day, Week, Month, Quarter, Weekdays vs. weekends etc."
*/

--------------- Which months have had the highest sales, what is the sales amount and contribution in percentage? -------------

SELECT TOP 1 *, ROUND((SALES * 100/(SELECT ROUND(SUM(TOTAL_AMOUNT_SPENT),2) FROM ORDER360)),2) AS PERCENTAGE_SALES FROM(
SELECT FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM') AS MONTH, ROUND(SUM(TOTAL_AMOUNT_SPENT),2) AS SALES FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM')
) AS A
ORDER BY SALES DESC

--------- Which months have had the least sales, what is the sales amount and contribution in percentage? ----------

SELECT TOP 1 *, ROUND((SALES * 100/(SELECT ROUND(SUM(TOTAL_AMOUNT_SPENT),2) FROM ORDER360)),4) AS PERCENTAGE_SALES FROM(
SELECT FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM') AS MONTH, ROUND(SUM(TOTAL_AMOUNT_SPENT),2) AS SALES FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM')
) AS A
ORDER BY SALES ASC

--------- SALES TRENDS BY MONTH ------

SELECT *, ROUND((SALES * 100/(SELECT ROUND(SUM(TOTAL_AMOUNT_SPENT),2) FROM ORDER360)),4) AS PERCENTAGE_SALES FROM(
SELECT FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM') AS MONTHS, ROUND(SUM(TOTAL_AMOUNT_SPENT),2) AS SALES FROM STORE360 AS S
JOIN ORDER360 AS O
ON O.Delivered_StoreID = S.StoreID
GROUP BY FORMAT(CAST(Bill_date_timestamp AS DATE),'yyyy-MM')
) AS A
ORDER BY MONTHS

----- ====== SALES BY DAYS OF WEEK ====== ---------
SELECT DATENAME(WEEKDAY, CAST(Bill_date_timestamp AS DATE)) AS Day_Name,
    COUNT(Order_id) AS Total_Orders,
    SUM(TOTAL_AMOUNT_SPENT) AS Total_Sales
FROM ORDER360
GROUP BY DATENAME(WEEKDAY, CAST(Bill_date_timestamp AS DATE))
ORDER BY CASE DATENAME(WEEKDAY, CAST(Bill_date_timestamp AS DATE))
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END

----- SALES BY WEEK NUMBER -------

SELECT 
    DATEPART(WEEK, CAST(Bill_date_timestamp AS DATE)) AS Week_Number,
    COUNT(Order_id) AS Total_Orders,
    SUM(TOTAL_AMOUNT_SPENT) AS Total_Sales
FROM ORDER360
GROUP BY DATEPART(WEEK, CAST(Bill_date_timestamp AS DATE))
ORDER BY Week_Number



SELECT 
    DATENAME(MONTH, CAST(Bill_date_timestamp AS DATE)) AS Month_Name,
    COUNT(Order_id) AS Total_Orders,
    SUM(TOTAL_AMOUNT_SPENT) AS Total_Sales
FROM ORDER360
GROUP BY DATENAME(MONTH, CAST(Bill_date_timestamp AS DATE))
ORDER BY CASE DATENAME(Month, CAST(Bill_date_timestamp AS DATE))
        WHEN 'January' THEN 1
        WHEN 'February' THEN 2
        WHEN 'March' THEN 3
        WHEN 'April' THEN 4
        WHEN 'May' THEN 5
        WHEN 'June' THEN 6
        WHEN 'July' THEN 7
		WHEN 'August' THEN 8
        WHEN 'September' THEN 9
        WHEN 'October' THEN 10
        WHEN 'November' THEN 11
        WHEN 'December' THEN 12
    END

---- ==== WEEKDAY === ---
SELECT 
    DATENAME(WEEKDAY, CAST(Bill_date_timestamp AS date)) AS DayOfWeek,
    SUM(TOTAL_AMOUNT_SPENT) AS TotalSales
FROM ORDER360
GROUP BY DATENAME(WEEKDAY, CAST(Bill_date_timestamp AS date))




SET DATEFIRST 1

SELECT TOP 5
    DATENAME(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)) AS Day_Of_Week,
    DATEPART(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)) AS WeekdayNum,
    SUM(TOTAL_AMOUNT_SPENT) AS TotalSales
FROM ORDER360
GROUP BY DATENAME(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)),
    DATEPART(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE))
ORDER BY WeekdayNum


SET DATEFIRST 1

SELECT TOP 2
    DATENAME(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)) AS Day_Of_Week,
    DATEPART(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)) AS WeekdayNum,
    SUM(TOTAL_AMOUNT_SPENT) AS TotalSales
FROM ORDER360
GROUP BY DATENAME(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE)),
    DATEPART(WEEKDAY, TRY_CAST(Bill_date_timestamp AS DATE))
ORDER BY WeekdayNum Desc


------------

SELECT MAX(CAST(Bill_date_timestamp AS DATE)) AS LastDate FROM ORDER360

WITH RFM AS (
  SELECT 
    Customer_id,
    DATEDIFF(DAY, MAX(CAST(Bill_date_timestamp AS DATE)), '2023-10-31') AS Recency,
    COUNT(DISTINCT order_id) AS Frequency,
    SUM([Total Amount]) AS Monetary
  FROM ORDER360
  GROUP BY Customer_id
  
)

SELECT *,
  NTILE(3) OVER (ORDER BY Recency desc) AS R_Score,     -- lower is better
  NTILE(3) OVER (ORDER BY Frequency asc) AS F_Score,  -- higher is better
  NTILE(3) OVER (ORDER BY Monetary asc) AS M_Score    -- higher is better
FROM RFM;







WITH RFM AS (
  SELECT 
    Customer_id,
    DATEDIFF(DAY, MAX(CAST(Bill_date_timestamp AS DATE)), '2023-10-31') AS Recency,
    COUNT(DISTINCT order_id) AS Frequency,
    SUM([Total Amount]) AS Monetary
  FROM ORDER360
  GROUP BY Customer_id
),
Scored_RFM AS (
  SELECT *,
    NTILE(3) OVER (ORDER BY Recency ASC) AS R_Score,     -- lower is better
    NTILE(3) OVER (ORDER BY Frequency DESC) AS F_Score,  -- higher is better
    NTILE(3) OVER (ORDER BY Monetary DESC) AS M_Score    -- higher is better 
  FROM RFM
)

SELECT *,
  CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
  CASE
    WHEN R_Score = 1 AND F_Score = 1 AND M_Score = 1 THEN 'Champions'
    WHEN R_Score = 1 AND F_Score = 1 THEN 'Loyal Customers'
    WHEN R_Score = 1 AND M_Score = 1 THEN 'Big Spenders'
    WHEN R_Score = 2 AND F_Score = 2 AND M_Score = 2 THEN 'Potential Loyalist'
    WHEN R_Score = 3 AND F_Score = 3 AND M_Score = 3 THEN 'Lost'
    WHEN R_Score = 3 AND F_Score = 1 THEN 'At Risk'
    WHEN F_Score = 3 AND M_Score = 3 THEN 'Need Attention'
    ELSE 'Others'
  END AS RFM_Label
FROM Scored_RFM;







WITH RFM AS (
  SELECT 
    Customer_id,
    DATEDIFF(DAY, MAX(CAST(Bill_date_timestamp AS DATE)), '2023-10-31') AS Recency,
    COUNT(DISTINCT order_id) AS Frequency,
    SUM([Total Amount]) AS Monetary
  FROM ORDER360
  GROUP BY Customer_id
  HAVING COUNT(DISTINCT order_id) > 1
),
Scored_RFM AS (
  SELECT *,
    NTILE(3) OVER (ORDER BY Recency ASC) AS R_Score,     -- lower is better
    NTILE(3) OVER (ORDER BY Frequency ASC) AS F_Score,  -- higher is better
    NTILE(3) OVER (ORDER BY Monetary ASC) AS M_Score    -- higher is better 
  FROM RFM
)

SELECT *,
  CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
  CASE
    WHEN R_Score = 1 AND F_Score = 3 AND M_Score = 3 THEN 'Champions'
    WHEN R_Score = 1 AND F_Score = 3 THEN 'Loyal Customers'
    WHEN R_Score = 1 AND M_Score = 3 THEN 'Big Spenders'
    WHEN R_Score = 2 AND F_Score = 2 AND M_Score = 2 THEN 'Potential Loyalist'
    WHEN R_Score = 3 AND F_Score = 1 AND M_Score = 1 THEN 'Lost'
    WHEN R_Score = 3 AND F_Score = 3 THEN 'At Risk'
    WHEN F_Score = 3 AND M_Score = 1 THEN 'Need Attention'
    ELSE 'Others'
  END AS RFM_Label
FROM Scored_RFM





--------- ========== CUSTOMER SEGMENTATION ============ -----------------

WITH RFM AS (
  SELECT 
    Customer_id,
    DATEDIFF(DAY, MAX(CAST(Bill_date_timestamp AS DATE)), '2023-10-31') AS Recency,
    COUNT(DISTINCT order_id) AS Frequency,
    SUM([Total Amount]) AS Monetary
  FROM ORDER360
  GROUP BY Customer_id
  --HAVING COUNT(DISTINCT order_id) > 1
)
, RFM_Scored AS (
  SELECT *,
    NTILE(3) OVER (ORDER BY Recency ASC) AS R_Score,
    NTILE(3) OVER (ORDER BY Frequency DESC) AS F_Score,
    NTILE(3) OVER (ORDER BY Monetary DESC) AS M_Score
  FROM RFM
)
, RFM_Final AS (
  SELECT *,
    CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
    (R_Score + F_Score + M_Score) AS Total_Score
  FROM RFM_Scored
)
SELECT *,
  CASE 
    WHEN Total_Score = 3 THEN 'Premium'
    WHEN Total_Score BETWEEN 4 AND 5 THEN 'Gold'
    WHEN Total_Score BETWEEN 6 AND 7 THEN 'Silver'
    ELSE 'Standard'
  END AS Customer_Segment
FROM RFM_Final
ORDER BY Total_Score DESC




------- ============= MOST POPULAR CATEGORY IN FIRST PURCHASE ========= ------
WITH FirstPurchase AS (
  SELECT 
    Customer_id,
    MIN(CAST(Bill_date_timestamp AS DATE)) AS First_Purchase_Date
  FROM ORDER360
  GROUP BY Customer_id
),
FirstPurchaseOrders AS (
  SELECT o.*
  FROM ORDER360 o
  JOIN FirstPurchase f
    ON o.Customer_id = f.Customer_id
   AND CAST(o.Bill_date_timestamp AS DATE) = f.First_Purchase_Date
),
WithCategory AS (
  SELECT fpo.Customer_id, O.category
  FROM FirstPurchaseOrders fpo
  JOIN  ORDER360 O
    ON fpo.product_id = O.product_id
)
SELECT 
  category,
  COUNT(DISTINCT Customer_id) AS Customers_First_Buying_This_Category
FROM WithCategory
GROUP BY category
ORDER BY Customers_First_Buying_This_Category DESC








--------- ========






SELECT DISTINCT Delivered_StoreID, COUNT(Customer_id) 
FROM ORDER360
GROUP BY Customer_id, Delivered_StoreID
HAVING COUNT(Order_id) > 1


WITH Repeat_Customers AS (
  SELECT Customer_id
  FROM ORDER360
  GROUP BY Customer_id
  HAVING COUNT(DISTINCT Order_id) > 1
)

SELECT O.Delivered_StoreID, COUNT(DISTINCT O.Customer_id) AS Repeat_Customer_Count
FROM Repeat_Customers RC
JOIN ORDER360 O
  ON RC.Customer_id = O.Customer_id
GROUP BY O.Delivered_StoreID;






SELECT Delivered_StoreID, COUNT(*) AS Repeat_Customers
FROM (
    SELECT Customer_id, Delivered_StoreID
    FROM ORDER360
    GROUP BY Customer_id, Delivered_StoreID
    HAVING COUNT(Order_id) > 1
) AS RepeatSub
GROUP BY Delivered_StoreID
ORDER BY Repeat_Customers DESC;



WITH Customer_Orders AS (
    SELECT 
        Customer_id, 
        Delivered_StoreID,
        Order_id,
        TRY_CAST(Bill_date_timestamp AS DATE) AS OrderDate
    FROM ORDER360
),
Repeat_Customers AS (
    SELECT 
        Customer_id
    FROM Customer_Orders
    GROUP BY Customer_id
    HAVING COUNT(DISTINCT Order_id) > 1
),
First_Store_Per_Repeat_Customer AS (
    SELECT 
        co.Customer_id,
        co.Delivered_StoreID,
        ROW_NUMBER() OVER (PARTITION BY co.Customer_id ORDER BY co.OrderDate) AS rn
    FROM Customer_Orders co
    INNER JOIN Repeat_Customers rc
        ON co.Customer_id = rc.Customer_id
)
SELECT 
    Delivered_StoreID,
    COUNT(*) AS Repeat_Customers
FROM First_Store_Per_Repeat_Customer
WHERE rn = 1
GROUP BY Delivered_StoreID
ORDER BY Repeat_Customers DESC;


------------- Behaviour of REPEAT  buyer  -------------------------
Select * from ORDER360

--------------- REVENUE BY REPEAT BUYERS -------------------------------

SELECT 
    YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
	MONTH(TRY_CAST(Bill_date_timestamp AS DATE)) AS Months,
    SUM(TOTAL_AMOUNT_SPENT) AS repeat_customer_revenue
FROM ORDER360
WHERE Customer_id IN (
    SELECT Customer_id
    FROM ORDER360
    GROUP BY Customer_id
    HAVING MIN(Clean_Bill_date_timestamp) != MAX(Clean_Bill_date_timestamp)
)
GROUP BY YEAR(TRY_CAST(Bill_date_timestamp AS DATE)),MONTH(TRY_CAST(Bill_date_timestamp AS DATE))
ORDER BY years,Months



SELECT 
    years,
    Months,
    ROUND(100.0 * repeat_customer_revenue / total_revenue, 2) AS percentage_revenue
FROM (
    SELECT 
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
        MONTH(TRY_CAST(Bill_date_timestamp AS DATE)) AS Months,
        SUM([Total Amount]) AS repeat_customer_revenue,
        (SELECT SUM([Total Amount])
         FROM ORDER360
         WHERE Customer_id IN (
             SELECT Customer_id
             FROM ORDER360
             GROUP BY Customer_id
             HAVING MIN(Clean_Bill_date_timestamp) != MAX(Clean_Bill_date_timestamp)
         )
        ) AS total_revenue
    FROM ORDER360
    WHERE Customer_id IN (
        SELECT Customer_id
        FROM ORDER360
        GROUP BY Customer_id
        HAVING MIN(Clean_Bill_date_timestamp) != MAX(Clean_Bill_date_timestamp)
    )
    GROUP BY 
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)),
        MONTH(TRY_CAST(Bill_date_timestamp AS DATE))
) AS a
ORDER BY years, Months



-------------- COUNT OF REPEAT CUSTOMER BY REGION ----------------------------

SELECT Region, COUNT(*) AS no_customers
FROM (
    SELECT Customer_id, Region
    FROM ORDER360 o
    WHERE Customer_id IN (
        SELECT Customer_id
        FROM ORDER360
        GROUP BY Customer_id
        HAVING MIN(Clean_Bill_date_timestamp) != MAX(Clean_Bill_date_timestamp)
    )
    AND Clean_Bill_date_timestamp = (
        SELECT MIN(Clean_Bill_date_timestamp)
        FROM ORDER360 o2
        WHERE o2.Customer_id = o.Customer_id
    )
) AS first_region_data
GROUP BY Region

-------------- COUNT OF REPEAT CUSTOMER BY STATE --------------------

Select  c.customer_state,count(distinct(Customer_id)) as no_customer from ORDER360 as o
join CUSTOMER360 as c
on o.Customer_id = c.Custid
where Customer_id in (select Customer_id
						from ORDER360
						group by Customer_id
						Having min(Clean_Bill_date_timestamp) != max(Clean_Bill_date_timestamp)
						)
Group by c.customer_state
order by no_customer desc



Select  s.StoreID,count(distinct(Customer_id)) as no_customer from ORDER360 as o
join STORE360 as s
on o.Delivered_StoreID = s.StoreID
where Customer_id in (select Customer_id
						from ORDER360
						group by Customer_id
						Having min(Clean_Bill_date_timestamp) != max(Clean_Bill_date_timestamp)
						)
Group by s.StoreID
order by no_customer desc




----------------- BEHAVIOUR OF ONE TIME BUYER ----------------------------
SELECT 
    YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
	MONTH(TRY_CAST(Bill_date_timestamp AS DATE)) AS Months,
    SUM(TOTAL_AMOUNT_SPENT) AS repeat_customer_revenue
FROM ORDER360
WHERE Customer_id IN (
    SELECT Customer_id
    FROM ORDER360
    GROUP BY Customer_id
    HAVING MIN(Clean_Bill_date_timestamp) != MAX(Clean_Bill_date_timestamp)
)
GROUP BY YEAR(TRY_CAST(Bill_date_timestamp AS DATE)),MONTH(TRY_CAST(Bill_date_timestamp AS DATE))
ORDER BY years,Months



SELECT 
    years,
    Months,
    100.0 * repeat_customer_revenue / total_revenue AS percentage_revenue
FROM (
    SELECT 
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
        MONTH(TRY_CAST(Bill_date_timestamp AS DATE)) AS Months,
        SUM([Total Amount]) AS repeat_customer_revenue,
        (SELECT SUM([Total Amount])
         FROM ORDER360
         WHERE Customer_id IN (
             SELECT Customer_id
             FROM ORDER360
             GROUP BY Customer_id
             HAVING MIN(Clean_Bill_date_timestamp) = MAX(Clean_Bill_date_timestamp)
         )
        ) AS total_revenue
    FROM ORDER360
    WHERE Customer_id IN (
        SELECT Customer_id
        FROM ORDER360
        GROUP BY Customer_id
        HAVING MIN(Clean_Bill_date_timestamp) = MAX(Clean_Bill_date_timestamp)
    )
    GROUP BY 
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)),
        MONTH(TRY_CAST(Bill_date_timestamp AS DATE))
) AS a
ORDER BY years, Months

SELECT 
    YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
	MONTH(TRY_CAST(Bill_date_timestamp AS DATE)) AS Months,
    SUM([Total Amount]) AS repeat_customer_revenue
FROM ORDER360
WHERE Customer_id IN (
    SELECT Customer_id
    FROM ORDER360
    GROUP BY Customer_id
    HAVING MIN(Clean_Bill_date_timestamp) = MAX(Clean_Bill_date_timestamp)
)
GROUP BY YEAR(TRY_CAST(Bill_date_timestamp AS DATE)),MONTH(TRY_CAST(Bill_date_timestamp AS DATE))
ORDER BY years,Months


-------------- COUNT OF REPEAT CUSTOMER BY REGION ----------------------------

SELECT Region, COUNT(*) AS no_customers

FROM (
    SELECT Customer_id, Region
    FROM ORDER360 o
    WHERE Customer_id IN (
        SELECT Customer_id
        FROM ORDER360
        GROUP BY Customer_id
        HAVING MIN(Clean_Bill_date_timestamp) = MAX(Clean_Bill_date_timestamp)
    )
    AND Clean_Bill_date_timestamp = (
        SELECT MIN(Clean_Bill_date_timestamp)
        FROM ORDER360 o2
        WHERE o2.Customer_id = o.Customer_id
    )
) AS first_region_data
GROUP BY Region



-------------- COUNT OF REPEAT CUSTOMER BY STATE --------------------

Select  c.customer_state,count(distinct(Customer_id)) as no_customer from ORDER360 as o
join CUSTOMER360 as c
on o.Customer_id = c.Custid
where Customer_id in (select Customer_id
						from ORDER360
						group by Customer_id
						Having min(Clean_Bill_date_timestamp) = max(Clean_Bill_date_timestamp)
						)
Group by c.customer_state
order by no_customer desc



Select  s.StoreID,count(distinct(Customer_id)) as no_customer from ORDER360 as o
join STORE360 as s
on o.Delivered_StoreID = s.StoreID
where Customer_id in (select Customer_id
						from ORDER360
						group by Customer_id
						Having min(Clean_Bill_date_timestamp) = max(Clean_Bill_date_timestamp)
						)
Group by s.StoreID
order by no_customer desc




select count(Category) over  Partition by (distinct Delivered_StoreID),category  from ORDER360
group by Delivered_StoreID,Category

SELECT 
    Delivered_StoreID,
    Category,
    COUNT(Category) OVER (PARTITION BY Delivered_StoreID, Category) AS Category_Count
FROM ORDER360
order by Category desc



----------- Cross sellling ------------

-- Step 1: Get unique OrderID & Category combinations
WITH OrderCategory AS (
    SELECT DISTINCT o.order_id, P.Category
    FROM Orders as o
	join ProductsInfo as p
	on o.product_id =p.product_id
)


SELECT 
    A.Category AS Category_1,
    B.Category AS Category_2,
    COUNT(DISTINCT A.Order_id) AS Orders_Together
FROM OrderCategory A
JOIN OrderCategory B 
    ON A.Order_id = B.Order_id
    AND A.Category < B.Category  
GROUP BY 
    A.Category, 
    B.Category
ORDER BY 
    Orders_Together DESC


	WITH OrderCategory AS (
    SELECT DISTINCT o.order_id, P.product_id
    FROM Orders as o
	join ProductsInfo as p
	on o.product_id =p.product_id
)


SELECT 
    A.product_id AS Category_1,
    B.product_id AS Category_2,
    COUNT(DISTINCT A.Order_id) AS Orders_Together
FROM OrderCategory A
JOIN OrderCategory B 
    ON A.Order_id = B.Order_id
    AND A.product_id < B.product_id  
GROUP BY 
    A.product_id, 
    B.product_id
ORDER BY 
    Orders_Together DESC





Select distinct Category, avg(Customer_Satisfaction_Score) as Ratings from ORDER360
group by Category
order by Ratings desc

select distinct (Category) from ORDER360



with total_sales as (
select YEAR(TRY_CAST(Bill_date_timestamp as date)) as years,
	sum([Total Amount]) as sales
	from Orders
	group by YEAR(TRY_CAST(Bill_date_timestamp as date))
) select years,
		sales,
		lag(sales,1) over (Partition by years order by sales) as lag_sales
		from total_sales


WITH total_sales AS (
    SELECT 
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
        SUM([Total Amount]) AS sales
    FROM Orders
    GROUP BY YEAR(TRY_CAST(Bill_date_timestamp AS DATE))
),
sales_lag as(
SELECT 
    years,
    sales,
    LAG(sales, 1) OVER (ORDER BY years) AS lag_sales
FROM total_sales
) select years,
		sales,
		lag_sales,
(sales - lag_sales)/(sales) *100 as differecne

from sales_lag

--------------- =================== KPI last year sales ================== ----------------

WITH total_sales AS (
    SELECT 
         YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS years,
        SUM([Total Amount]) AS sales
    FROM Orders
    GROUP BY YEAR(TRY_CAST(Bill_date_timestamp AS DATE))
),
sales_lag as(
SELECT 
    years,
    sales,
    LAG(sales, 1) OVER (ORDER BY years) AS lag_sales
FROM total_sales
), sales_lag_diff as(
select  years,	
(sales - lag_sales)/(sales) *100 as sales_differecne
	from sales_lag
), last_year_sales_diff as ( 
select top 1 years,
	sales_differecne
from sales_lag_diff
order by years desc
) 
Select sales_differecne from last_year_sales_diff





----------------- ========================== Churn Rate Percentage ====================== --------------------------

WITH Monthly_Customers AS (
    SELECT 
        Customer_id,
        FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM') AS OrderMonth
    FROM Orders
    GROUP BY Customer_id, FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'yyyy-MM')
),

Customer_Months AS (
    SELECT 
        curr.OrderMonth AS CurrentMonth,
        COUNT(DISTINCT prev.Customer_id) AS Customers_LastMonth,
        COUNT(DISTINCT CASE WHEN curr.Customer_id IS NULL THEN prev.Customer_id END) AS Churned_Customers
    FROM (
        SELECT DISTINCT OrderMonth FROM Monthly_Customers
    ) months
    LEFT JOIN Monthly_Customers prev
        ON months.OrderMonth = FORMAT(DATEADD(MONTH, 1, TRY_CAST(prev.OrderMonth + '-01' AS DATE)), 'yyyy-MM')
    LEFT JOIN Monthly_Customers curr
        ON prev.Customer_id = curr.Customer_id
        AND curr.OrderMonth = months.OrderMonth
    GROUP BY curr.OrderMonth
), output_for_powerBI as(

SELECT TOP 1
    CurrentMonth,
    --Customers_LastMonth,
    --Churned_Customers,
    ROUND(CAST(Churned_Customers AS FLOAT) / NULLIF(Customers_LastMonth, 0) * 100, 2) AS Churn_Rate_Percentage
FROM Customer_Months
ORDER BY CurrentMonth
) Select Churn_Rate_Percentage from output_for_powerBI




-- Step 1: Get customers by year
WITH Customer_Years AS (
    SELECT 
        DISTINCT Customer_id,
        YEAR(TRY_CAST(Bill_date_timestamp AS DATE)) AS OrderYear
    FROM Orders
),

-- Step 2: Get active customer count by year
Yearly_Customers AS (
    SELECT 
        OrderYear,
        COUNT(DISTINCT Customer_id) AS Customers_This_Year
    FROM Customer_Years
    GROUP BY OrderYear
),

-- Step 3: Get churned customers (those who were active in Year N-1 but not in Year N)
Churn_Calculation AS (
    SELECT 
        prev.OrderYear + 1 AS Churn_Year,
        COUNT(DISTINCT prev.Customer_id) AS Customers_Last_Year,
        COUNT(DISTINCT CASE WHEN curr.Customer_id IS NULL THEN prev.Customer_id END) AS Churned_Customers
    FROM Customer_Years prev
    LEFT JOIN Customer_Years curr
        ON prev.Customer_id = curr.Customer_id
        AND curr.OrderYear = prev.OrderYear + 1
    GROUP BY prev.OrderYear + 1
),
output_powerBI as(
-- Step 4: Final Output

SELECT 
    Churn_Year,
    Customers_Last_Year,
    Churned_Customers,
    ROUND(CAST(Churned_Customers AS FLOAT) / NULLIF(Customers_Last_Year, 0) * 100, 2) AS Churn_Rate_Percentage
FROM Churn_Calculation

) 
Select top 2 Churn_year, churn_rate_Percentage from output_powerBI
ORDER BY Churn_Year