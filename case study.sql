create database casestudy1
use casestudy1
ALTER TABLE Customer ADD CONSTRAINT PK PRIMARY KEY (customer_Id)
ALTER TABLE Transactions ADD CONSTRAINT FK  FOREIGN KEY (CUST_ID) REFERENCES Customer (customer_Id)
ALTER TABLE [dbo].[Transactions] ALTER COLUMN QTY INT;
ALTER TABLE [dbo].[Transactions] ALTER COLUMN RATE DECIMAL(15,2);
ALTER TABLE [dbo].[Transactions] ALTER COLUMN TAX DECIMAL(15,2);
ALTER TABLE [dbo].[Transactions] ALTER COLUMN TOTAL_AMT DECIMAL(15,2);



select * 
from Customer
select *
from Transactions
select *
from prod_cat_info
-----DATA PREPARATION AND UNDERSTANDING
--1. What is the total number of rows in each of the 3 tables in the database?

select * from(
select 'Customer' AS TABLE_NAME, count(*) as RECORDS from Customer CUSTOMER UNION ALL
SELECT 'Transactions' AS TABLE_NAME, COUNT(*) AS RECORDS FROM TRANSACTIONS UNION ALL
SELECT 'PROD_CAT_CODE' AS TABLE_NAME, COUNT(*) AS RECORDS FROM prod_cat_info
) ABC
--2. What is the total number of transactions that have a return?
SELECT
COUNT(transaction_id) QTY
from Transactions
WHERE QTY <0
--2ed 
SELECT
COUNT(Qty) QTY
from Transactions
WHERE QTY <0
--3.	As you would have noticed, the dates provided across the datasets are not in a correct format. As first steps,
-- pls convert the date variables into valid date formats before proceeding ahead

UPDATE Customer  SET DOB=CONVERT(DATE,DOB,23) 
GO
UPDATE Transactions SET tran_date=CONVERT(DATE,tran_date,23) 
GO

--4.What is the time range of the transaction data available for analysis? Show the output in number of days,
---- months and years simultaneously in different columns.
select min(tran_date),
       max(tran_date),
        DATEDIFF (yyyy,min(tran_date),max(tran_date))total_year,  
        DATEDIFF (mm,min(tran_date),max(tran_date)) total_month,
		DATEDIFF (day,min(tran_date),max(tran_date)) total_day
 from [dbo].[Transactions]

 select min(tran_date),
       max(tran_date),
        DATEDIFF (yyyy,min(tran_date),max(tran_date)) year, 
        DATEDIFF (mm,min(tran_date),max(tran_date)) - DATEDIFF (yyyy,min(tran_date),max(tran_date))*12 month ,
		DATEDIFF (day,min(tran_date),max(tran_date))- DATEDIFF (yyyy,min(tran_date),max(tran_date))*365
		-(DATEDIFF (mm,min(tran_date),max(tran_date)) - DATEDIFF (yyyy,min(tran_date),max(tran_date))*12)*31 day
 from transactions


--5.Which product category does the sub-category “DIY” belong to?


SELECT
PROD_CAT
FROM prod_cat_info
WHERE prod_subcat='DIY'



//*DATA ANALYSIS*//
--1.Which channel is most frequently used for transactions?

SELECT TOP 1
  Store_type
                                                                  --count(Store_type) as Store_type_#
  from TRANSACTIONS
  group by Store_type
  order by count(Store_type) DESC
   

--2. What is the count of Male and Female customers in the database?

select 
       count(case when gender = 'M' then 1 end) as Male, 
       count(case when gender = 'F' then 1 end) as Female
	   --count(case when gender = '' then 1 end) as kuchh_nahi
from CUSTOMER


--3.From which city do we have the maximum number of customers and how many?

select TOP 1
  city_code,
  count(city_code) as city_#
  from CUSTOMER
  group by city_code
  order by count(city_code) DESC
--4.How many sub-categories are there under the Books category?
 SELECT
 COUNT(2) #sub_categories
 FROM prod_cat_info
 WHERE prod_cat='Books'
 --5.	What is the maximum quantity of products ever ordered?
  SELECT
	MAX(Qty)
FROM TRANSACTIONS
--6. What is the net total revenue generated in categories Electronics and Books?
SELECT
PROD_CAT,
SUM(total_amt) AS REVENUE
FROM TRANSACTIONS T1 LEFT JOIN prod_cat_info P1
                 ON T1.prod_cat_code=P1.prod_cat_code
				 AND T1.prod_subcat_code=P1.prod_sub_cat_code
WHERE P1.prod_cat='Electronics' OR P1.prod_cat='Books'
GROUP BY PROD_CAT
--7.How many customers have >10 transactions with us, excluding returns?

 select cust_id, COUNT(cust_id) AS Count_of_Transactions
from TRANSACTIONS
where Qty >= 0
group by cust_id
having COUNT(cust_id) > 10


--8. What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
 SELECT
 COALESCE(P1.prod_cat,'GRAND TOTAL' )AS CATEGORY,
 SUM(total_amt) AS combined_revenue
FROM TRANSACTIONS T1 LEFT JOIN prod_cat_info P1
                 ON T1.prod_cat_code=P1.prod_cat_code
				 AND T1.prod_subcat_code=P1.prod_sub_cat_code
WHERE P1.prod_cat IN ('Electronics' , 'Clothing') AND T1.Store_type= 'Flagship store'
GROUP BY ROLLUP (P1.prod_cat)


--9. What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.

SELECT prod_subcat as subcat,
gender, 
sum(total_amt) as total_revenue
from TRANSACTIONS T1
left join CUSTOMER C1
  on T1.cust_id = C1.customer_ID
left join Prod_cat_info P1
  on T1.prod_cat_code = P1.prod_cat_code
  and T1.prod_subcat_code=P1.prod_sub_cat_code
where Gender like 'M' and prod_Cat in (
  select prod_Cat
  from Prod_cat_info 
  where prod_Cat like 'Electronics'
)
group by prod_subcat,Gender


--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

//*This is not an ans 
select
[Subcategory] = P.prod_subcat,
[Sales] =   Round(SUM(cast( case when T.Qty > 0 then total_amt else 0 end as float)),2) , 
[Returns] = Round(SUM(cast( case when T.Qty < 0 then total_amt else 0 end as float)),2) ,
[Profit] =  Round(SUM(cast(total_amt as float)),2), 
[%_Returs]= (Round(SUM(cast( case when T.Qty < 0 then total_amt else 0 end as float)),2)/Round(SUM(cast(total_amt as float)),2))*100,
[%_sales]=(Round(SUM(cast( case when T.Qty > 0 then total_amt else 0 end as float)),2)/Round(SUM(cast(total_amt as float)),2))*100
from tbl_Tran as T
INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code
group by P.prod_subcat
order by [%_sales] desc
this is not an ans
select top 5
[Subcategory] = P.prod_subcat,
[Sales] =   Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2) , 
[Returns] = Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2) ,
[Profit] =  Round(SUM(cast(T.Qty  as float)),2), 
[%_Returs]= (Round(SUM(cast( case when T.Qty < 0 then T.Qty  else 0 end as float)),2)/Round(SUM(cast(T.Qty as float)),2))*100,
[%_sales]=(Round(SUM(cast( case when T.Qty > 0 then T.Qty  else 0 end as float)),2)/Round(SUM(cast(T.Qty  as float)),2))*100
from tbl_Tran as T
INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code
group by P.prod_subcat
order by [%_sales] desc

 --p.prod_cat category,
 -- Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)[Sales]  , 
-- Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2) [Returns] ,
--Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
 --            - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)[total_qty],*//

--10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
--SELECT top 5
-- P.prod_subcat [Subcategory] ,

---((Round(SUM(cast( case when T.Qty < 0 then T.Qty  else 0 end as float)),2))/
--              (Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
--             - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)))*100[%_Returs],
--((Round(SUM(cast( case when T.Qty > 0 then T.Qty  else 0 end as float)),2))/
--              (Round(SUM(cast( case when T.Qty > 0 then T.Qty else 0 end as float)),2)
--             - Round(SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end as float)),2)))*100[%_sales]
--from TRANSACTIONS as T
--INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code=P.prod_cat_code
--group by P.prod_subcat,P.prod_cat
--order by [%_sales] desc


SELECT top 5  --% sale and and returns on qty
 P.prod_subcat [Subcategory] ,

-((SUM(cast( case when T.Qty < 0 then T.Qty  else 0 end  as decimal )))/
              ((SUM(cast( case when T.Qty > 0 then T.Qty else 0 end  as decimal)))
             - (SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end  as decimal )))))*100[%_Returs],
(SUM(cast( case when T.Qty > 0 then T.Qty  else 0 end  as decimal )))/
             ( (SUM(cast( case when T.Qty > 0 then T.Qty else 0 end  as decimal )))
             - SUM(cast( case when T.Qty < 0 then T.Qty   else 0 end  as decimal)))*100[%_sales]
from TRANSACTIONS as T
INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code=P.prod_cat_code
group by P.prod_subcat,P.prod_cat
order by [%_sales] desc


SELECT top 5   --% sale and and returns on total_amt
 P.prod_subcat [Subcategory] ,

-((SUM(cast( case when T.Qty < 0 then T.TOTAL_AMT  else 0 end  as decimal )))/
              ((SUM(cast( case when T.Qty > 0 then T.TOTAL_AMT else 0 end  as decimal)))
             - (SUM(cast( case when T.Qty < 0 then T.TOTAL_AMT   else 0 end  as decimal )))))*100[%_Returs],
(SUM(cast( case when T.Qty > 0 then T.TOTAL_AMT  else 0 end  as decimal )))/
             ( (SUM(cast( case when T.Qty > 0 then T.TOTAL_AMT else 0 end  as decimal )))
             - SUM(cast( case when T.Qty < 0 then T.TOTAL_AMT   else 0 end  as decimal)))*100[%_sales]
from TRANSACTIONS as T
INNER JOIN prod_cat_info as P ON T.prod_subcat_code = P.prod_sub_cat_code and T.prod_cat_code=P.prod_cat_code
group by P.prod_subcat,P.prod_cat
order by [%_sales] desc

--11. For all customers aged between 25 to 35 years find what is the net total revenue generated by
-- these consumers in last 30 days of transactions from max transaction date available in the data?


select 
 customer_Id,
 SUM(total_amt) MAX_TRAN,
 tran_date,
 DATEDIFF(YYYY,C1.DOB,T1.TRAN_DATE) AGE
    from Customer C1 LEFT join TRANSACTIONS T1
                     on T1.cust_id = C1.customer_ID
WHERE DATEDIFF(YYYY,C1.DOB,T1.TRAN_DATE) BETWEEN 25 AND 35					 
GROUP BY C1.DOB,T1.TRAN_DATE,customer_Id,TOTAL_AMT
HAVING  tran_date>=(select  DATEADD(day, -30,max(tran_date) )from TRANSACTIONS)
ORDER BY sum(total_amt) desc





--12. Which product category has seen the max value of returns in the last 3 months of transactions?
select  top 1 prod_cat,
	 -sum(qty) sum_qty_Returns
 FROM TRANSACTIONS T1 LEFT JOIN prod_cat_info P1
                 ON T1.prod_cat_code=P1.prod_cat_code
				 AND T1.prod_subcat_code=P1.prod_sub_cat_code
where Qty<0 and tran_date>=(select  DATEADD(MONTH, -3,max(tran_date) )from TRANSACTIONS)

group by prod_cat 
having sum(T1.qty)<0 
order by sum(T1.qty) 



--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?



SELECT top 1
Store_type,
SUM(total_amt) AS Total_total_amt,
SUM(Qty) AS Total_Qty
from TRANSACTIONS
group by Store_type 
ORDER BY  sum(Qty) DESC


--14. What are the categories for which average revenue is above the overall average.
select
prod_cat
--avg(total_amt)average_revenue 
 FROM TRANSACTIONS T1 LEFT JOIN prod_cat_info P1
                 ON T1.prod_cat_code=P1.prod_cat_code
				 AND T1.prod_subcat_code=P1.prod_sub_cat_code
group by prod_cat
having avg(total_amt)> (select avg(total_amt) from TRANSACTIONS)
ORDER BY AVG(total_amt) desc


--15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
select top 5 prod_cat, 
prod_subcat,
avg(total_amt)average_revenue ,
sum(total_amt) total_revenue,
sum(qty) qty
 FROM TRANSACTIONS T1 LEFT JOIN prod_cat_info P1
                 ON T1.prod_cat_code=P1.prod_cat_code
				 AND T1.prod_subcat_code=P1.prod_sub_cat_code
group by prod_cat,prod_subcat
having avg(total_amt)> (select avg(total_amt) from TRANSACTIONS)
ORDER BY sum(qty) desc









