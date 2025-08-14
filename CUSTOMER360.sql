--------------- ================== CUSTOMER 360 ================ -----------------------
SELECT C.*,
	O.order_id AS order_id,
	MIN(TRY_CAST(Bill_date_timestamp AS DATETIME)) AS First_tran_date,
	MAX(TRY_CAST(Bill_date_timestamp AS DATETIME)) AS Last_tran_date,
	DATEDIFF(DAY, MIN(TRY_CAST(Bill_date_timestamp AS DATETIME)), 
				  MAX(TRY_CAST(Bill_date_timestamp AS DATETIME))) AS Days_Difference,
	COUNT(DISTINCT(o.order_id)) AS No_of_Transaction,
	SUM([Total Amount]) AS TOTAL_AMOUNT_SPENT,
	ROUND(SUM([Total Amount])-SUM(Quantity * [Cost Per Unit]),2) AS TOTAL_PROFIT,
	SUM(Discount * Quantity) AS TOTAL_DISCOUNT,
	SUM(Quantity) AS TOTAL_QUANTITY,
	COUNT(DISTINCT O.product_id) AS DICTINCT_PROD_COUNT,
	COUNT(DISTINCT Category) AS DISTINCT_CATEGORY_COUNT,
	COUNT(DISTINCT Delivered_StoreID) AS DISTINCT_STORE_ID_COUNT,
	COUNT(CASE WHEN O.Discount > 0 THEN (O.ORDER_ID) ELSE NULL END) AS DISCOUNT_TRAN_COUNT,
	OP.payment_type,
	COUNT(DISTINCT payment_type) AS PAYMENT_TYPE_COUNT,
	SUM(CASE WHEN payment_type = 'Credit_Card' THEN([Total Amount]) ELSE 0 END) AS CREDIT_CARD_AMT,
	SUM(CASE WHEN payment_type = 'Debit_Card' THEN([Total Amount]) ELSE 0 END) AS DEBIT_CARD_AMT,
	SUM(CASE WHEN payment_type = 'UPI/Cash' THEN([Total Amount]) ELSE 0 END) AS UPI_CASH_AMT,
	SUM(CASE WHEN payment_type = 'Voucher' THEN([Total Amount]) ELSE 0 END) AS VOUCHER_AMT,
-- analysis by diffenrent channel --
	O.Channel,
-- Instore channel --
	COUNT(DISTINCT CASE WHEN O.Channel = 'Instore' THEN(O.order_id) ELSE NULL END ) INSTORE_FREQ,
	SUM(CASE WHEN O.Channel = 'Instore' THEN ([Total Amount]) ELSE 0 END) AS INSTORE_TOTAL_AMOUNT,
	ROUND(SUM(CASE WHEN O.Channel = 'Instore' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit]) ELSE 0 END),2) AS INSTORE_PROFIT,
	SUM(CASE WHEN O.Channel = 'Instore' THEN Discount ELSE 0 END) AS INSTORE_DISCOUNT,
	SUM(CASE WHEN O.Channel = 'Instore' THEN Quantity ELSE 0 END) AS INSTORE_QUANTITY,
	COUNT(DISTINCT CASE WHEN O.Channel = 'Instore' THEN (payment_type) ELSE NULL END) AS INSTORE_DISTINCT_PAYMENT_TYPE,
	SUM(CASE WHEN payment_type = 'Credit_Card' AND O.Channel = 'Instore' THEN ([Total Amount]) ELSE 0 END) AS INSTORE_CC_AMT,
	SUM(CASE WHEN payment_type = 'Debit_Card' AND O.Channel = 'Instore' THEN ([Total Amount]) ELSE 0 END) AS INSTORE_DC_AMT,
	SUM(CASE WHEN payment_type = 'UPI/Cash' AND O.Channel = 'Instore' THEN ([Total Amount]) ELSE 0 END) AS INSTORE_UPI_CASH_AMT,
	SUM(CASE WHEN payment_type = 'Voucher' AND O.Channel = 'Instore' THEN ([Total Amount]) ELSE 0 END) AS INSTORE_VOUCHER_AMT,
-- Phone delicvery --
	COUNT(DISTINCT CASE WHEN O.Channel = 'Phone Delivery' THEN(O.order_id) ELSE NULL END ) Phone_Delivery_FREQ,
	SUM(CASE WHEN O.Channel = 'Phone Delivery' THEN ([Total Amount]) ELSE 0 END) AS Phone_Delivery_TOTAL_AMOUNT,
	ROUND(SUM(CASE WHEN O.Channel = 'Phone Delivery' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit]) ELSE 0 END),2) AS Phone_Delivery_PROFIT,
	SUM(CASE WHEN O.Channel = 'Phone Delivery' THEN Discount ELSE 0 END) AS Phone_Delivery_DISCOUNT,
	SUM(CASE WHEN O.Channel = 'Phone Delivery' THEN Quantity ELSE 0 END) AS Phone_Delivery_QUANTITY,
	COUNT(DISTINCT CASE WHEN O.Channel = 'Phone Delivery' THEN (payment_type) ELSE NULL END) AS Phone_Delivery_DISTINCT_PAYMENT_TYPE,
	SUM(CASE WHEN payment_type = 'Credit_Card' AND O.Channel = 'Phone Delivery' THEN ([Total Amount]) ELSE 0 END) AS Phone_Delivery_CC_AMT,
	SUM(CASE WHEN payment_type = 'Debit_Card' AND O.Channel = 'Phone Delivery' THEN ([Total Amount]) ELSE 0 END) AS Phone_Delivery_DC_AMT,
	SUM(CASE WHEN payment_type = 'UPI/Cash' AND O.Channel = 'Phone Delivery' THEN ([Total Amount]) ELSE 0 END) AS Phone_Delivery_UPI_CASH_AMT,
	SUM(CASE WHEN payment_type = 'Voucher' AND O.Channel = 'Phone Delivery' THEN ([Total Amount]) ELSE 0 END) AS Phone_Delivery_VOUCHER_AMT,
-- Online --
	COUNT(DISTINCT CASE WHEN O.Channel = 'Online' THEN(O.order_id) ELSE NULL END ) Online_FREQ,
	SUM(CASE WHEN O.Channel = 'Online' THEN ([Total Amount]) ELSE 0 END) AS Online_TOTAL_AMOUNT,
	ROUND(SUM(CASE WHEN O.Channel = 'Online' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit]) ELSE 0 END),2) AS Online_PROFIT,
	SUM(CASE WHEN O.Channel = 'Online' THEN Discount ELSE 0 END) AS Online_DISCOUNT,
	SUM(CASE WHEN O.Channel = 'Online' THEN Quantity ELSE 0 END) AS Online_QUANTITY,
	COUNT(DISTINCT CASE WHEN O.Channel = 'Online' THEN (payment_type) ELSE NULL END) AS Online_DISTINCT_PAYMENT_TYPE,
	SUM(CASE WHEN payment_type = 'Credit_Card' AND O.Channel = 'Online' THEN ([Total Amount]) ELSE 0 END) AS Online_CC_AMT,
	SUM(CASE WHEN payment_type = 'Debit_Card' AND O.Channel = 'Online' THEN ([Total Amount]) ELSE 0 END) AS Online_DC_AMT,
	SUM(CASE WHEN payment_type = 'UPI/Cash' AND O.Channel = 'Online' THEN ([Total Amount]) ELSE 0 END) AS Online_UPI_CASH_AMT,
	SUM(CASE WHEN payment_type = 'Voucher' AND O.Channel = 'Online' THEN ([Total Amount]) ELSE 0 END) AS Online_VOUCHER_AMT,

	--- Analysis on different product category ---
	P.Category,
	--- Product Category Food & Beverages ---
	COUNT (DISTINCT CASE WHEN P.Category = 'Food & Beverages' THEN (O.order_id) ELSE NULL END) AS Food_Beverages_TRANSACTIONS,
	COUNT(CASE WHEN P.Category = 'Food & Beverages' THEN(O.product_id) ELSE NULL END) AS Food_Beverages_PROD_ID_COUNT,
	SUM(CASE WHEN P.Category = 'Food & Beverages' THEN (Quantity) ELSE 0 END) AS Food_Beverages_QTY,
	SUM(CASE WHEN P.Category = 'Food & Beverages' THEN ([Total Amount]) ELSE 0 END) AS Food_Beverages_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Food & Beverages' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Food_Beverages_PROFIT,
	SUM(CASE WHEN P.Category = 'Food & Beverages' THEN (O.Discount) ELSE 0 END) AS Food_Beverages_DISCOUNT,
	--- product category Construction_Tools ---
	COUNT (DISTINCT CASE WHEN P.Category = 'Construction_Tools' THEN (O.order_id) ELSE NULL END) AS Construction_Tools_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Construction_Tools' THEN (Quantity) ELSE 0 END) AS Construction_Tools_QTY,
	SUM(CASE WHEN P.Category = 'Construction_Tools' THEN ([Total Amount]) ELSE 0 END) AS Construction_Tools_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Construction_Tools' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Construction_Tools_PROFIT,
	SUM(CASE WHEN P.Category = 'Construction_Tools' THEN (O.Discount) ELSE 0 END) AS Construction_Tools_DISCOUNT,
	--- product category Fashion ----
	COUNT (DISTINCT CASE WHEN P.Category = 'Fashion' THEN (O.order_id) ELSE NULL END) AS Fashion_TRANSACTIONS,
	COUNT(CASE WHEN P.Category = 'Fashion' THEN(O.product_id) ELSE NULL END) AS Fashion_ID_COUNT,
	SUM(CASE WHEN P.Category = 'Fashion' THEN (Quantity) ELSE 0 END) AS Fashion_QTY,
	SUM(CASE WHEN P.Category = 'Fashion' THEN ([Total Amount]) ELSE 0 END) AS Fashion_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Fashion' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Fashion_PROFIT,
	SUM(CASE WHEN P.Category = 'Fashion' THEN (O.Discount) ELSE 0 END) AS Fashion_DISCOUNT,
	--- product category Stationery ---
	COUNT (DISTINCT CASE WHEN P.Category = 'Stationery' THEN (O.order_id) ELSE NULL END) AS Stationery_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Stationery' THEN (Quantity) ELSE 0 END) AS Stationery_QTY,
	SUM(CASE WHEN P.Category = 'Stationery' THEN ([Total Amount]) ELSE 0 END) AS Stationery_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Stationery' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Stationery_PROFIT,
	SUM(CASE WHEN P.Category = 'Stationery' THEN (O.Discount) ELSE 0 END) AS Stationery_DISCOUNT,
	-- product category Pet_Shop --
	COUNT (DISTINCT CASE WHEN P.Category = 'Pet_Shop' THEN (O.order_id) ELSE NULL END) AS Pet_Shop_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Pet_Shop' THEN (Quantity) ELSE 0 END) AS Pet_Shop_QTY,
	SUM(CASE WHEN P.Category = 'Pet_Shop' THEN ([Total Amount]) ELSE 0 END) AS Pet_Shop_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Pet_Shop' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Pet_Shop_PROFIT,
	SUM(CASE WHEN P.Category = 'Pet_Shop' THEN (O.Discount) ELSE 0 END) AS Pet_Shop_DISCOUNT,
	-- product category Luggage_Accessories --
	COUNT (DISTINCT CASE WHEN P.Category = 'Luggage_Accessories' THEN (O.order_id) ELSE NULL END) AS Luggage_Accessories_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Luggage_Accessories' THEN (Quantity) ELSE 0 END) AS Luggage_Accessories_QTY,
	SUM(CASE WHEN P.Category = 'Luggage_Accessories' THEN ([Total Amount]) ELSE 0 END) AS Luggage_Accessories_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Luggage_Accessories' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Luggage_Accessories_PROFIT,
	SUM(CASE WHEN P.Category = 'Luggage_Accessories' THEN (O.Discount) ELSE 0 END) AS Luggage_Accessories_DISCOUNT,
	-- product category Electronics --
	COUNT (DISTINCT CASE WHEN P.Category = 'Electronics' THEN (O.order_id) ELSE NULL END) AS Electronics_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Electronics' THEN (Quantity) ELSE 0 END) AS Electronics_QTY,
	SUM(CASE WHEN P.Category = 'Electronics' THEN ([Total Amount]) ELSE 0 END) AS Electronics_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Electronics' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Electronics_PROFIT,
	SUM(CASE WHEN P.Category = 'Electronics' THEN (O.Discount) ELSE 0 END) AS Electronics_DISCOUNT,
	-- product category Toys & Gifts --
	COUNT (DISTINCT CASE WHEN P.Category = 'Toys & Gifts' THEN (O.order_id) ELSE NULL END) AS Toys_Gifts_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Toys & Gifts' THEN (Quantity) ELSE 0 END) AS Toys_Gifts_QTY,
	SUM(CASE WHEN P.Category = 'Toys & Gifts' THEN ([Total Amount]) ELSE 0 END) AS Toys_Gifts_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Toys & Gifts' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Toys_Gifts_PROFIT,
	SUM(CASE WHEN P.Category = 'Toys & Gifts' THEN (O.Discount) ELSE 0 END) AS Toys_Gifts_DISCOUNT,
	-- product category Furniture --
	COUNT (DISTINCT CASE WHEN P.Category = 'Furniture' THEN (O.order_id) ELSE NULL END) AS Furniture_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Furniture' THEN (Quantity) ELSE 0 END) AS Furniture_QTY,
	SUM(CASE WHEN P.Category = 'Furniture' THEN ([Total Amount]) ELSE 0 END) AS Furniture_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Furniture' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Furniture_PROFIT,
	SUM(CASE WHEN P.Category = 'Furniture' THEN (O.Discount) ELSE 0 END) AS Furniture_DISCOUNT,
	---Product Category auto ----

	COUNT (DISTINCT CASE WHEN P.Category = 'Auto' THEN (O.order_id) ELSE NULL END) AS AUTO_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Auto' THEN (Quantity) ELSE 0 END) AS AUTO_QTY,
	SUM(CASE WHEN P.Category = 'Auto' THEN ([Total Amount]) ELSE 0 END) AS AUTO_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Auto' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS AUTO_PROFIT,
	SUM(CASE WHEN P.Category = 'Auto' THEN (O.Discount) ELSE 0 END) AS AUTO_DISCOUNT,
	-- product category Baby --
	COUNT (DISTINCT CASE WHEN P.Category = 'Baby' THEN (O.order_id) ELSE NULL END) AS Baby_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Baby' THEN (Quantity) ELSE 0 END) AS Baby_QTY,
	SUM(CASE WHEN P.Category = 'Baby' THEN ([Total Amount]) ELSE 0 END) AS Baby_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Baby' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Baby_PROFIT,
	SUM(CASE WHEN P.Category = 'Baby' THEN (O.Discount) ELSE 0 END) AS Baby_DISCOUNT,
	-- product category Computers & Accessories --
	COUNT (DISTINCT CASE WHEN P.Category = 'Computers & Accessories' THEN (O.order_id) ELSE NULL END) AS Computers_Accessories_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Computers & Accessories' THEN (Quantity) ELSE 0 END) AS Computers_Accessories_QTY,
	SUM(CASE WHEN P.Category = 'Computers & Accessories' THEN ([Total Amount]) ELSE 0 END) AS Computers_Accessories_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Computers & Accessories' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Computers_Accessories_PROFIT,
	SUM(CASE WHEN P.Category = 'Computers & Accessories' THEN (O.Discount) ELSE 0 END) AS Computers_Accessories_DISCOUNT,
	-- product category Home_Appliances --
	COUNT (DISTINCT CASE WHEN P.Category = 'Home_Appliances' THEN (O.order_id) ELSE NULL END) AS Home_Appliances_TRANSACTIONS,
	SUM(CASE WHEN P.Category = 'Home_Appliances' THEN (Quantity) ELSE 0 END) AS Home_Appliances_QTY,
	SUM(CASE WHEN P.Category = 'Home_Appliances' THEN ([Total Amount]) ELSE 0 END) AS Home_Appliances_TOTAL_AMT,
	ROUND(SUM(CASE WHEN P.Category = 'Home_Appliances' THEN ([Total Amount]) - (O.Quantity * [Cost Per Unit])ELSE 0 END),2) AS Home_Appliances_PROFIT,
	SUM(CASE WHEN P.Category = 'Home_Appliances' THEN (O.Discount) ELSE 0 END) AS Home_Appliances_DISCOUNT,
	R.Customer_Satisfaction_Score
	INTO CUSTOMER360

FROM Customers AS C
JOIN Orders AS O
ON C.Custid = O.Customer_id
JOIN OrderPayments AS OP
ON OP.order_id = O.order_id
JOIN OrderReview_Ratings AS R
ON R.order_id =O.order_id
JOIN ProductsInfo AS P
ON P.product_id = O.product_id
JOIN StoresInfo AS S
ON S.StoreID = O.Delivered_StoreID

GROUP BY C.Custid,C.customer_city,C.customer_state,Gender,R.Customer_Satisfaction_Score,P.Category,O.Channel,OP.payment_type,o.order_id

SELECT TOP 1 * FROM CUSTOMER360
