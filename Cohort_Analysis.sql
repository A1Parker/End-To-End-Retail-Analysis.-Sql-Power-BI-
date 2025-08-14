SELECT * FROM ORDER360
--(Year_diff btw Cohort Month Var and First tran date)*12 + month_diff btw Cohort month var and First tran date

	------- Creating a table for cochosrt analysis -----------

SELECT 
    order_id,
    Customer_id,
    FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'MM-dd-yyyy') AS DATES,
    FORMAT(MIN(TRY_CAST(Bill_date_timestamp AS DATE)) OVER (PARTITION BY Customer_id), 'MM-dd-yyyy') AS First_tran_date,
    FORMAT(TRY_CAST(Bill_date_timestamp AS DATE), 'MM-yyyy') AS COHORT_MONTH,
    DATEDIFF(MONTH, 
        MIN(TRY_CAST(Bill_date_timestamp AS DATE)) OVER (PARTITION BY Customer_id), 
        TRY_CAST(Bill_date_timestamp AS DATE)
    ) AS Cohort_Index

INTO Cohort_Analysis_Table
FROM ORDER360
GROUP BY order_id, Customer_id, Bill_date_timestamp

-------- Retention by month -----------

SELECT 
    Cohort_Month,
    Cohort_Index,
    COUNT(DISTINCT Customer_id) AS Retained_Customers
FROM Cohort_Analysis_Table
GROUP BY Cohort_Month, Cohort_Index
ORDER BY COHORT_MONTH, Cohort_Index

--------- retention by month in percentage ---------

SELECT 
    A.Cohort_Month,
    A.Cohort_Index,
    COUNT(DISTINCT A.Customer_id) AS Retained_Customers,
    B.Month_Customers,
    CAST(COUNT(DISTINCT A.Customer_id) AS FLOAT) / (B.Month_Customers) * 100 AS Retention_Percentage
FROM Cohort_Analysis_Table A
JOIN (
    SELECT 
        Cohort_Month,
        COUNT(DISTINCT Customer_id) AS Month_Customers
    FROM Cohort_Analysis_Table
    WHERE Cohort_Index = 0
    GROUP BY Cohort_Month
) B ON A.Cohort_Month = B.Cohort_Month
GROUP BY A.COHORT_MONTH,A.Cohort_Index, B.Month_Customers
ORDER BY A.COHORT_MONTH



---- created a segmentation table for further analysis ----------

SELECT CU.customer_state,CA.Customer_id,ca.order_id,CA.DATES,CA.First_tran_date,CA.COHORT_MONTH,CA.Cohort_Index 

INTO SEGEMANTED_CITY

FROM Cohort_Analysis_Table AS CA
JOIN CUSTOMER360 AS CU
ON CA.Customer_id = CU.Custid

SELECT * FROM SEGEMANTED_CITY

--------------- ========================= Segementaion based cohort by customer state =================    -----------------

-- Add half-year buckets for cohort and transaction
SELECT 
    customer_state,
    Customer_id,
    CONCAT(YEAR(TRY_CAST(DATES AS DATE)), '-', 
           CASE WHEN MONTH(TRY_CAST(DATES AS DATE)) <= 6 THEN 'H1' ELSE 'H2' END) AS txn_halfyear,
    CONCAT(YEAR(TRY_CAST(First_tran_date AS DATE)), '-', 
           CASE WHEN MONTH(TRY_CAST(First_tran_date AS DATE)) <= 6 THEN 'H1' ELSE 'H2' END) AS cohort_halfyear,
    DATEDIFF(MONTH, TRY_CAST(First_tran_date AS DATE), TRY_CAST(DATES AS DATE)) / 6 AS cohort_index
INTO #HalfYearCohortData
FROM SEGEMANTED_CITY
-- Aggregate unique customer counts
SELECT 
    customer_state,
    cohort_halfyear,
    cohort_index,
    COUNT(DISTINCT Customer_id) AS num_customers
INTO #HalfYearCohortCounts
FROM #HalfYearCohortData
WHERE cohort_index BETWEEN 0 AND 2  -- For 3 half-year periods
GROUP BY customer_state, cohort_halfyear, cohort_index

-- retention by half-year index
SELECT 
    customer_state,
    cohort_halfyear,
    MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END) AS H0,
    MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END) AS H1,
    MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) AS H2,
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_H1_Percent,
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_H2_Percent
FROM #HalfYearCohortCounts
GROUP BY customer_state,cohort_halfyear
ORDER BY customer_state,cohort_halfyear

----------- XXXXXXXXXXXXXXXXXXXXX --------------------XXXXXXXXXXXXXXXXXXXXXXXX--------------------XXXXXXXXXXXXXXXXXXXXXXX-------------------

---- created a segmentation table for REGION analysis ----------

SELECT O.Region,CA.Customer_id,ca.order_id,CA.DATES,CA.First_tran_date,CA.COHORT_MONTH,CA.Cohort_Index 

INTO SEGEMANTED_REGION

FROM Cohort_Analysis_Table AS CA
JOIN ORDER360 AS O
ON CA.Customer_id = O.Customer_id

--------
-- Add half-year buckets for cohort and transaction
SELECT 
    Region,
    Customer_id,   
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(DATES AS DATE)), '-', YEAR(TRY_CAST(DATES AS DATE))) AS txn_quarter,    
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(First_tran_date AS DATE)), '-', YEAR(TRY_CAST(First_tran_date AS DATE))) AS cohort_quarter,    
    DATEDIFF(MONTH, TRY_CAST(First_tran_date AS DATE), TRY_CAST(DATES AS DATE)) / 3 AS cohort_index
INTO #QuarterREGION
FROM SEGEMANTED_REGION


-- Create quarter label from cohort date + offset
SELECT 
    Region,
    cohort_quarter,
    cohort_index,
    DATEADD(MONTH, cohort_index * 3, TRY_CAST(CONCAT(RIGHT(cohort_quarter, 4), '-', 
           CASE LEFT(cohort_quarter, 2)
                WHEN 'Q1' THEN '01'
                WHEN 'Q2' THEN '04'
                WHEN 'Q3' THEN '07'
                WHEN 'Q4' THEN '10'
           END, '-01') AS DATE)) AS quarter_date,
    COUNT(DISTINCT Customer_id) AS num_customers
INTO #QuarterREGIONounts_1
FROM #QuarterREGION
WHERE cohort_index BETWEEN 0 AND 4
GROUP BY Region, cohort_quarter, cohort_index

----------------

SELECT 
    Region,
    --cohort_quarter,

    -- Number of customers in each quarter
    MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END) AS CUSTOMER_FIRST_PURCHASE,
    MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) AS Q1,
    MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) AS Q2,
    MAX(CASE WHEN cohort_index = 3 THEN num_customers ELSE 0 END) AS Q3,
    MAX(CASE WHEN cohort_index = 4 THEN num_customers ELSE 0 END) AS Q4,
	-- Retention percentages
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q1_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q2_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 3 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q3_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 4 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q4_Percent

 
FROM #QuarterREGIONounts_1
GROUP BY Region
ORDER BY Region



---------------------================
WITH RFM AS (
  SELECT 
    Customer_id,
    DATEDIFF(DAY, MAX(CAST(Bill_date_timestamp AS DATE)), '2023-10-31') AS Recency,
    COUNT(DISTINCT order_id) AS Frequency,
    SUM([Total Amount]) AS Monetary
  FROM ORDER360
  GROUP BY Customer_id
),
RFM_Scored AS (
  SELECT *,
    NTILE(3) OVER (ORDER BY Recency ASC) AS R_Score,
    NTILE(3) OVER (ORDER BY Frequency DESC) AS F_Score,
    NTILE(3) OVER (ORDER BY Monetary DESC) AS M_Score
  FROM RFM
),
RFM_Final AS (
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

INTO RFM_Segmentation 

FROM RFM_Final
ORDER BY Total_Score DESC


------------------

SELECT CA.Customer_id,DATES,First_tran_date,COHORT_MONTH,Cohort_Index,Customer_Segment,Monetary 
INTO SGSP_SEGMENTATION
FROM RFM_Segmentation AS RF
JOIN Cohort_Analysis_Table AS CA
ON CA.Customer_id = RF.Customer_id

-- Add half-year buckets for cohort and transaction
SELECT 
    Customer_Segment,
    Customer_id,
    CONCAT(YEAR(TRY_CAST(DATES AS DATE)), '-', 
           CASE WHEN MONTH(TRY_CAST(DATES AS DATE)) <= 6 THEN 'H1' ELSE 'H2' END) AS txn_halfyear,
    CONCAT(YEAR(TRY_CAST(First_tran_date AS DATE)), '-', 
           CASE WHEN MONTH(TRY_CAST(First_tran_date AS DATE)) <= 6 THEN 'H1' ELSE 'H2' END) AS cohort_halfyear,
    DATEDIFF(MONTH, TRY_CAST(First_tran_date AS DATE), TRY_CAST(DATES AS DATE)) / 6 AS cohort_index
INTO #HalfYearSGSP
FROM SGSP_SEGMENTATION

-- Aggregate unique customer counts
SELECT 
    Customer_Segment,
    cohort_halfyear,
    cohort_index,
    COUNT(DISTINCT Customer_id) AS num_customers
INTO #HalfYearSGSPCounts
FROM #HalfYearSGSP
WHERE cohort_index BETWEEN 0 AND 2  -- For 3 half-year periods
GROUP BY Customer_Segment, cohort_halfyear, cohort_index

-- retention by half-year index
SELECT 
    Customer_Segment,
    --cohort_halfyear,
    MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END) AS H0,
    MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) AS H1,
    MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) AS H2,
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_H1_Percent,
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_H2_Percent
FROM #HalfYearSGSPCounts
GROUP BY Customer_Segment
ORDER BY Customer_Segment



--------------------- =============== Qurterly based Retention of segmented customer ==============  -----------------



-- Add half-year buckets for cohort and transaction
SELECT 
    Customer_Segment,
    Customer_id,   
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(DATES AS DATE)), '-', YEAR(TRY_CAST(DATES AS DATE))) AS txn_quarter,    
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(First_tran_date AS DATE)), '-', YEAR(TRY_CAST(First_tran_date AS DATE))) AS cohort_quarter,    
    DATEDIFF(MONTH, TRY_CAST(First_tran_date AS DATE), TRY_CAST(DATES AS DATE)) / 3 AS cohort_index
INTO #QuarterSGSP
FROM SGSP_SEGMENTATION


-- Create quarter label from cohort date + offset
SELECT 
    Customer_Segment,
    cohort_quarter,
    cohort_index,
    DATEADD(MONTH, cohort_index * 3, TRY_CAST(CONCAT(RIGHT(cohort_quarter, 4), '-', 
           CASE LEFT(cohort_quarter, 2)
                WHEN 'Q1' THEN '01'
                WHEN 'Q2' THEN '04'
                WHEN 'Q3' THEN '07'
                WHEN 'Q4' THEN '10'
           END, '-01') AS DATE)) AS quarter_date,
    COUNT(DISTINCT Customer_id) AS num_customers
INTO #QuarterSGSPCounts_1
FROM #QuarterSGSP
WHERE cohort_index BETWEEN 0 AND 4
GROUP BY Customer_Segment, cohort_quarter, cohort_index

----------------

SELECT 
    Customer_Segment,
    cohort_quarter,

    -- Number of customers in each quarter
    MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END) AS Q0,
    MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) AS Q1,
    MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) AS Q2,
    MAX(CASE WHEN cohort_index = 3 THEN num_customers ELSE 0 END) AS Q3,
    MAX(CASE WHEN cohort_index = 4 THEN num_customers ELSE 0 END) AS Q4,
	-- Retention percentages
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 1 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q1_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 2 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q2_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 3 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q3_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 4 THEN num_customers ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN num_customers ELSE 0 END), 0), 2) AS Retention_Q4_Percent

 
FROM #QuarterSGSPCounts_1
GROUP BY Customer_Segment, cohort_quarter
ORDER BY Customer_Segment, cohort_quarter




---------------------------- ================== MONETARY BASED ================== ------------------------------

-- Add half-year buckets for cohort and transaction
SELECT 
    Customer_Segment,
    Customer_id,
	Monetary,
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(DATES AS DATE)), '-', YEAR(TRY_CAST(DATES AS DATE))) AS txn_quarter,    
    CONCAT('Q', DATEPART(QUARTER, TRY_CAST(First_tran_date AS DATE)), '-', YEAR(TRY_CAST(First_tran_date AS DATE))) AS cohort_quarter,    
    DATEDIFF(MONTH, TRY_CAST(First_tran_date AS DATE), TRY_CAST(DATES AS DATE)) / 3 AS cohort_index
INTO #MONETARY_Q
FROM SGSP_SEGMENTATION


-- Create quarter label from cohort date + offset
SELECT 
    Customer_Segment,
    cohort_quarter,
    cohort_index,
	SUM(MONETARY) AS TOTAL_SPENT,
    DATEADD(MONTH, cohort_index * 3, TRY_CAST(CONCAT(RIGHT(cohort_quarter, 4), '-', 
           CASE LEFT(cohort_quarter, 2)
                WHEN 'Q1' THEN '01'
                WHEN 'Q2' THEN '04'
                WHEN 'Q3' THEN '07'
                WHEN 'Q4' THEN '10'
           END, '-01') AS DATE)) AS quarter_date,
    COUNT(DISTINCT Customer_id) AS num_customers
INTO #QuarterMONETARYCounts_1
FROM #MONETARY_Q
WHERE cohort_index BETWEEN 0 AND 4
GROUP BY Customer_Segment, cohort_quarter, cohort_index

----------------

SELECT 
    Customer_Segment,
    SUM(TOTAL_SPENT) AS SPENT,

    -- Number of customers in each quarter
    MAX(CASE WHEN cohort_index = 0 THEN TOTAL_SPENT ELSE 0 END) AS FIRST_PURCHASE_SUM,
    MAX(CASE WHEN cohort_index = 1 THEN TOTAL_SPENT ELSE 0 END) AS Q1,
    MAX(CASE WHEN cohort_index = 2 THEN TOTAL_SPENT ELSE 0 END) AS Q2,
    MAX(CASE WHEN cohort_index = 3 THEN TOTAL_SPENT ELSE 0 END) AS Q3,
    MAX(CASE WHEN cohort_index = 4 THEN TOTAL_SPENT ELSE 0 END) AS Q4,
	-- Retention percentages
    ROUND(100.0 * MAX(CASE WHEN cohort_index = 1 THEN TOTAL_SPENT ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN TOTAL_SPENT ELSE 0 END), 0), 2) AS Retention_Q1_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 2 THEN TOTAL_SPENT ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN TOTAL_SPENT ELSE 0 END), 0), 2) AS Retention_Q2_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 3 THEN TOTAL_SPENT ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN TOTAL_SPENT ELSE 0 END), 0), 2) AS Retention_Q3_Percent,

    ROUND(100.0 * MAX(CASE WHEN cohort_index = 4 THEN TOTAL_SPENT ELSE 0 END) 
                / NULLIF(MAX(CASE WHEN cohort_index = 0 THEN TOTAL_SPENT ELSE 0 END), 0), 2) AS Retention_Q4_Percent

 
FROM #QuarterMONETARYCounts_1
GROUP BY Customer_Segment
ORDER BY Customer_Segment






SELECT 
    Cohort_Month,
    Cohort_Index,
    COUNT(DISTINCT Customer_id) AS Retained_Customers
FROM Cohort_Analysis_Table
GROUP BY Cohort_Month, Cohort_Index
ORDER BY COHORT_MONTH, Cohort_Index






-- Step 1: Clean and format order dates
WITH orders_cleaned AS (
    SELECT 
        customer_id,
        CAST(Bill_date_timestamp AS DATE) AS order_date,
        DATEFROMPARTS(
            YEAR(CAST(Bill_date_timestamp AS DATE)), 
            MONTH(CAST(Bill_date_timestamp AS DATE)), 
            1
        ) AS order_month
    FROM orders
),

-- Step 2: Identify the cohort (first purchase month for each customer)
cohorts AS (
    SELECT 
        customer_id,
        MIN(order_month) AS cohort_month
    FROM orders_cleaned
    GROUP BY customer_id
),

-- Step 3: Join cohort with each order to track retention
cohort_orders AS (
    SELECT 
        oc.customer_id,
        c.cohort_month,
        oc.order_month
    FROM orders_cleaned oc
    JOIN cohorts c ON oc.customer_id = c.customer_id
)

-- Step 4: Aggregate the retention counts per cohort and order month
SELECT 
    cohort_month,
    order_month,
    COUNT(DISTINCT customer_id) AS retained_customers
FROM cohort_orders
GROUP BY cohort_month, order_month
ORDER BY cohort_month

---------------------------------------------------------------------------------------------------------------------------------

;WITH FirstPurchase AS (
    SELECT
        CUSTOMER_ID,
        MIN(TRY_CAST(Bill_date_timestamp AS DATE)) AS first_purchase_date
    FROM ORDER360
    GROUP BY CUSTOMER_ID
),
Cohorts AS (
    SELECT
        CUSTOMER_ID,
        DATEFROMPARTS(YEAR(first_purchase_date), MONTH(first_purchase_date), 1) AS cohort_month
    FROM FirstPurchase
),
OrderCohorts AS (
    SELECT
        o.CUSTOMER_ID,
        DATEFROMPARTS(YEAR(o.Bill_date_timestamp), MONTH(o.Bill_date_timestamp), 1) AS order_month,
        c.cohort_month,
        DATEDIFF(MONTH, c.cohort_month, DATEFROMPARTS(YEAR(o.Bill_date_timestamp), MONTH(o.Bill_date_timestamp), 1)) AS month_number
    FROM ORDER360 o
    INNER JOIN Cohorts c ON o.CUSTOMER_ID = c.CUSTOMER_ID
)
SELECT
    FORMAT(cohort_month, 'yyyy-MM') AS [Cohort Month],
    COUNT(DISTINCT CASE WHEN month_number = 0 THEN CUSTOMER_ID END) AS [First Purchase],
    COUNT(DISTINCT CASE WHEN month_number = 1 THEN CUSTOMER_ID END) AS [M1],
    COUNT(DISTINCT CASE WHEN month_number = 2 THEN CUSTOMER_ID END) AS [M2],
    COUNT(DISTINCT CASE WHEN month_number = 3 THEN CUSTOMER_ID END) AS [M3],
    COUNT(DISTINCT CASE WHEN month_number = 4 THEN CUSTOMER_ID END) AS [M4],
    COUNT(DISTINCT CASE WHEN month_number = 5 THEN CUSTOMER_ID END) AS [M5],
    COUNT(DISTINCT CASE WHEN month_number = 6 THEN CUSTOMER_ID END) AS [M6],
    COUNT(DISTINCT CASE WHEN month_number = 7 THEN CUSTOMER_ID END) AS [M7],
    COUNT(DISTINCT CASE WHEN month_number = 8 THEN CUSTOMER_ID END) AS [M8],
    COUNT(DISTINCT CASE WHEN month_number = 9 THEN CUSTOMER_ID END) AS [M9],
    COUNT(DISTINCT CASE WHEN month_number = 10 THEN CUSTOMER_ID END) AS [M10],
    COUNT(DISTINCT CASE WHEN month_number = 11 THEN CUSTOMER_ID END) AS [M11],
    COUNT(DISTINCT CASE WHEN month_number = 12 THEN CUSTOMER_ID END) AS [M12]
FROM OrderCohorts
WHERE month_number BETWEEN 0 AND 12
GROUP BY cohort_month
ORDER BY cohort_month;


