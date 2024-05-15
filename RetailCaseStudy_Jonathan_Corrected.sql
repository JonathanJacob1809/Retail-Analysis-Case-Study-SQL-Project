---- DATA PREPARATION AND UNDERSTANDING

-- 1. What is the total number of rows in each of the 3 tables in the database ?
SELECT count(*) as _count FROM Customer
UNION
SELECT count(*) as _count FROM Transactions
UNION
SELECT count(*) as _count FROM Prodcatinfo

-- 2. What is the total number of transactions that have a return ?
SELECT COUNT(DISTINCT transaction_id) AS total_transact FROM Transactions
WHERE total_amt < 0

-- 3. Correcting Date Formats
SELECT tran_date, convert(date,tran_date,101) as converted_tran_date from Transactions
SELECT DOB, convert(date,DOB,101) as converted_DOB from Customer

-- 4. Time Range of transactional data
SELECT
DATEDIFF(YEAR,MIN(tran_date),MAX(tran_date)) AS year_diff,
DATEDIFF(MONTH,MIN(tran_date),MAX(tran_date)) AS month_diff,
DATEDIFF(DAY,MIN(tran_date),MAX(tran_date)) AS day_diff
FROM Transactions

-- ALTERNATE METHOD
SELECT
DATEDIFF(YEAR,MIN(convert(date,tran_date,101)),MAX(convert(date,tran_date,101))) AS year_diff,
DATEDIFF(MONTH,MIN(convert(date,tran_date,101)),MAX(convert(date,tran_date,101))) AS month_diff,
DATEDIFF(DAY,MIN(convert(date,tran_date,101)),MAX(convert(date,tran_date,101))) AS day_diff
FROM Transactions


--5. Sub category 'DIY' belongs to which product category
SELECT prod_cat,prod_subcat FROM Prodcatinfo
WHERE prod_subcat = 'DIY'

--- DATA ANALYSIS

-- Q1
SELECT TOP 1 Store_type,COUNT(Store_type) AS channel_count FROM Transactions
GROUP BY Store_type
ORDER BY channel_count DESC

-- Q2
SELECT Gender, COUNT(Gender) AS total_gender_count FROM Customer
WHERE Gender IS NOT NULL
GROUP BY Gender

-- Q3
SELECT TOP 1 city_code,COUNT(*) AS no_of_customers FROM Customer
GROUP BY city_code
ORDER BY no_of_customers DESC

-- Q4
SELECT prod_subcat,prod_cat FROM Prodcatinfo
WHERE prod_cat = 'Books'

-- Q5
SELECT prod_cat_code, MAX(Qty) AS max_qty FROM Transactions
WHERE Qty > 0
GROUP BY prod_cat_code

-- Q6
SELECT SUM(CAST(T.total_amt AS FLOAT)) AS total_revenue
FROM Transactions AS T
INNER JOIN Prodcatinfo AS PD
ON T.prod_cat_code = PD.prod_cat_code AND T.prod_subcat_code = PD.prod_sub_cat_code
WHERE PD.prod_cat IN('Electronics','Books')

-- Q7
SELECT COUNT(*) AS TOT_CNT FROM
(
SELECT cust_id, COUNT(DISTINCT(transaction_id)) as Transaction_Count
FROM Transactions
WHERE total_amt >0
GROUP BY cust_id
HAVING COUNT(DISTINCT(transaction_id))>10
) AS T1

-- Q8
SELECT SUM(T.total_amt) AS combined_revenue
FROM Transactions AS T
INNER JOIN Prodcatinfo AS P
ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
WHERE P.prod_cat IN ('Clothing', 'Electronics') AND T.Store_type = 'Flagship store' AND T.Qty >0

-- Q9
SELECT P.prod_subcat,SUM(T.total_amt) AS Total_Revenue
FROM Customer AS C
INNER JOIN Transactions AS T
ON C.customer_Id = T.cust_id
INNER JOIN Prodcatinfo AS P
ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code=P.prod_sub_cat_code
WHERE C.Gender = 'M' AND P.prod_cat = 'Electronics'
GROUP BY P.prod_subcat

-- Q10
SELECT T_SALES.prod_subcat,SALES_PERCENTAGE,RETURN_PERCENTAGE FROM
(
SELECT TOP 5 
P.prod_subcat, 
(SUM(total_amt)*100 /(SELECT SUM(total_amt) from Transactions WHERE Qty > 0)) as SALES_PERCENTAGE
from Transactions as T
INNER JOIN 
Prodcatinfo as P
ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
WHERE T.Qty > 0
GROUP BY P.prod_subcat
ORDER BY SALES_PERCENTAGE DESC
) AS T_SALES
INNER JOIN
(
SELECT 
P.prod_subcat, 
(SUM(total_amt)*100 /(SELECT SUM(total_amt) from Transactions WHERE Qty < 0)) as RETURN_PERCENTAGE
from Transactions as T
INNER JOIN 
Prodcatinfo as P
ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
WHERE T.Qty < 0
GROUP BY P.prod_subcat
) AS T_RETURN
ON T_SALES.prod_subcat=T_RETURN.prod_subcat;


-- Q11
SELECT * FROM(
SELECT * FROM(
SELECT customer_Id,DATEDIFF(YEAR,DOB,MAX_DATE) AS AGE, TOTAL_REVENUE FROM
(
SELECT C.customer_Id,C.DOB,MAX(CONVERT(DATE,tran_date,101)) AS MAX_DATE, SUM(T.total_amt) AS TOTAL_REVENUE
FROM Customer AS C
INNER JOIN Transactions AS T
ON C.customer_Id = T.cust_id
WHERE T.Qty>0
GROUP BY C.customer_Id,C.DOB
) AS A
) AS B
WHERE AGE BETWEEN 25 AND 35
) AS C
INNER JOIN
(
-- LAST 30 DAYS OF TRANSACTIONS
SELECT CUST_ID,CONVERT(DATE,tran_date,101) AS TRANS_DATE
FROM Transactions
GROUP BY CUST_ID,CONVERT(DATE,tran_date,101)
HAVING CONVERT(DATE,tran_date,101) >= (SELECT DATEADD(DAY,-30,MAX(CONVERT(DATE,tran_date,101))) AS CUTOFF_DATE FROM Transactions)
) AS D
ON C.customer_Id = D.CUST_ID

-- Q12
SELECT TOP 1 prod_cat_code,SUM(_RETURNS) AS TOT_RETURNS FROM(
SELECT prod_cat_code,CONVERT(DATE,tran_date,101) AS TRANS_DATE, SUM(Qty) AS _RETURNS
FROM Transactions
WHERE Qty < 0
GROUP BY prod_cat_code,CONVERT(DATE,tran_date,101)
HAVING CONVERT(DATE,tran_date,101) >= (SELECT DATEADD(MONTH,-3,MAX(CONVERT(DATE,tran_date,101))) AS CUTOFF_DATE FROM Transactions)
) AS A
GROUP BY prod_cat_code
ORDER BY TOT_RETURNS

-- Q13
SELECT TOP 1 
Store_type, SUM(total_amt) AS Total_sales, SUM(Qty) AS Quantity
FROM Transactions
WHERE Qty > 0
GROUP BY Store_type
ORDER BY SUM(total_amt) DESC, SUM(Qty) DESC

-- Q14
SELECT P.prod_cat,P.prod_cat_code, AVG(total_amt) AS avg_revenue
FROM Transactions AS T
INNER JOIN Prodcatinfo AS P
ON T.prod_cat_code = P.prod_cat_code AND T.prod_subcat_code = P.prod_sub_cat_code
WHERE T.Qty>0
GROUP BY P.prod_cat,P.prod_cat_code
HAVING AVG(total_amt) > (SELECT AVG(total_amt) FROM Transactions WHERE Qty >0)

-- Q15

SELECT prod_subcat_code, AVG(total_amt) AS avg_revenue, SUM(total_amt) AS total_revenue
FROM Transactions
WHERE Qty>0 AND prod_cat_code IN
(
SELECT TOP 5 prod_cat_code
FROM Transactions
WHERE Qty > 0
GROUP BY prod_cat_code
ORDER BY SUM(Qty) DESC
)
GROUP BY prod_subcat_code
