#Orders table DDL:

create table orders (order_id BIGINT, user_id INT,eval_set string, order_number decimal(10,1),order_dow int,order_hour_of_day int,days_since_prior_order STRING)  ROW FORMAT DELIMITED FIELDS TERMINATED BY ',';

#Products DDL

CREATE TABLE products( product_id INT, product_name string, aisle_id INT, department_id INT) 
 row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
 with serdeproperties (
   "separatorChar" = ",",
   "quoteChar"     = "\""
 )
 STORED AS TEXTFILE ;

order_products:

CREATE TABLE order_products( order_id BIGINT, product_id INT, add_to_cart_order INT ,reordered INT )  
row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
 with serdeproperties (
   "separatorChar" = ",",
   "quoteChar"     = "\""
 )
 STORED AS TEXTFILE ;

#LOADING DATA:

LOAD DATA LOCAL INPATH '/usr/data/orders.csv' INTO TABLE orders; 

LOAD DATA LOCAL INPATH '/usr/data/products.csv' INTO TABLE products;

LOAD DATA LOCAL INPATH '/usr/data/order_products.csv' INTO TABLE order_products;

CREATE TABLE OREDERS_Dup as SELECT order_id, user_id, eval_set, order_number, order_dow, order_hour_of_day, case WHEN days_since_prior_order IS NULL THEN 0 ELSE days_since_prior_order END AS days_since_prior_order from orders 

# DROP ORDERS TABLE AND RENAME OREDERS_Dup
drop table ORDERS
"ALTER TABLE OREDERS_Dup RENAME TO ORDERS"hive 

#Query 1:
SELECT user_id, COUNT(order_id) as order_id FROM ORDERS GROUP BY user_id ORDER BY order_id desc LIMIT 10 ;

310     100
313     100
210     100
626     95
516     94
409     87
496     83
27      82
54      78
140     77

#Query 2:

select user_id, sum(total_order) as final_total_user from (
select o.user_id, sum(op.add_to_cart_order) as total_order from orders o JOIN order_products op  on o.order_id = op.order_id
group by o.user_id, op.add_to_cart_order order by total_order desc ) c group by user_id order by final_total_user desc LIMIT 20

Alternative #2:
select o.user_id, sum(c.total_order) as total_order_user from orders o join 
(select sum(op.add_to_cart_order) as total_order,op.order_id from order_products op group by op.add_to_cart_order, op.order_id ) c on o.order_id = c.order_id
group by user_id order by total_order_user desc limit 10

Another Alternative #3:

Query2:
select o.user_id, sum(c.total_order) as total_order_by_customer from orders o join (
select distinct(order_id) as order_id, sum(add_to_cart_order) over(partition by order_id) as total_order from order_products) c
on (o.order_id = c.order_id)
group by o.user_id
order by total_order_by_customer desc
LIMIT 10;

Query 3:
#top 10 best seller products
select p.product_name,sum(op.add_to_cart_order) as total_order  from order_products op join products p on op.product_id = p.product_id
group by p.product_name,op.add_to_cart_order
order by total_order desc
LIMIT 10

select p.product_id, sum(total_order) as total_products_purchased from products p  join 
(select op.product_id,sum(op.add_to_cart_order) as total_order  from order_products op
group by op.product_id) c on p.product_id = c.product_id
group by p.product_id, total_order
order by total_products_purchased desc
LIMIT 10; 

SELECT p.product_id, p.product_name ,c.total_order_product
from products p join (
select distinct(product_id) as product_id , sum(add_to_cart_order) over(partition by product_id) as total_order_product
from order_products) c
on p.product_id = c.product_id
order by total_order_product desc
LIMIT 10;

Saving results to HDFS: 
INSERT OVERWRITE DIRECTORY "/HDFS/top_products_sold"
SELECT p.product_id, p.product_name ,c.total_order_product
from products p join (
select distinct(product_id) as product_id , sum(add_to_cart_order) over(partition by product_id) as total_order_product
from order_products) c
on p.product_id = c.product_id
order by total_order_product desc
LIMIT 10;

Query 4: 
select order_dow , count(*) from orders group by order_dow;

select distinct(product_id), round(add_to_cart_per_product/total_count,2) from (
select product_id , sum(add_to_cart_order) over(partition by product_id) as add_to_cart_per_product, c.total_count
from order_products , ( select sum(add_to_cart_order) as total_count from order_products)c)

with cte_table as 
select p.product_id as product_id, sum(add_to_cart_order) over(partition by product_id) as add_to_cart_per_product, c.total_count
from order_products p cross join ( select sum(add_to_cart_order) as total_count from order_products ) 
 (select distinct(product_id), round(add_to_cart_per_product/c.total_count,2)
from cte_table);

Query 5: 

select distinct(user_id), max(days_since_prior_order) over(partition by user_id), count(*) over(partition by order_id) as total_count from orders
order by total_count desc limit 10;

select user_id, max_days, total_count,  max_days/total_count from (
select distinct(user_id) as user_id, max(days_since_prior_order) over(partition by user_id) as max_days, count(*) over(partition by order_id) as total_count from orders
order by total_count desc) c limit 10;
Query 6:
with q1 as (
select p.product_id as product_id, cast(NULLIF(sum(add_to_cart_order) over(partition by product_id),0) as double) as add_to_cart_per_product, cast(round(c.total_count,2 )as double) as total_count
from order_products p cross join ( select sum(add_to_cart_order)as total_count from order_products ) c )
 select distinct(product_id), cast(round((NULLIF(add_to_cart_per_product,0)/total_count) * 100 ,3) as decimal(10,3))  as frequency from q1 order by frequency desc limit 20;

Query7: 
select p.department_id ,sum(s.product_count) as product_count_dept from products p inner join 
(select distinct(product_id), count(order_id) over(partition by product_id) as product_count from order_products order by product_count desc) s
on p.product_id = s.product_id group by p.department_id order by product_count_dept desc limit 20 ;

over(partition by p.department_id) 


#insert data into bucketed tab
INSERT OVERWRITE TABLE orders_b
select * from orders;

order by : 
Time Taken : 23.176 seconds
Map: 1 Reduce : 1 Job
Total MapReduce CPU Time Spent: 7 seconds 490 msec

cluster by : 
Time Taken : 27.922 seconds
Map: 1 Reduce : 1 Job
Total MapReduce CPU Time Spent: 6 seconds 510 msec

sort by
Stage-Stage-1: Map: 1  Reduce: 1 
Total MapReduce CPU Time Spent: 7 seconds 50 msec

Distribute by:
Stage-Stage-1: Map: 1  Reduce: 1
Total MapReduce CPU Time Spent: 6 seconds 740 msec