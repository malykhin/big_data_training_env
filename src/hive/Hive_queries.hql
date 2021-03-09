#Orders table DDL:

create table orders (order_id BIGINT, user_id INT,eval_set string, order_number decimal(10,1),order_dow int,order_hour_of_day int,days_since_prior_order STRING)  
row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
 with serdeproperties (
   "separatorChar" = ",",
   "quoteChar"     = "\""
 )
 STORED AS TEXTFILE ;


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

#Query2:
select o.user_id, sum(c.total_order) as total_order_by_customer from orders o join (
select distinct(order_id) as order_id, sum(add_to_cart_order) over(partition by order_id) as total_order from order_products) c
on (o.order_id = c.order_id)
group by o.user_id
order by total_order_by_customer desc
LIMIT 10;

#Query 3:
#top 10 best seller products
#Solution 1:
select p.product_id,p.product_name,sum(op.add_to_cart_order) as total_order from order_products op join products p on op.product_id = p.product_id
group by p.product_name,op.add_to_cart_order
order by total_order desc
LIMIT 10
#Solution 2:
SELECT p.product_id, p.product_name ,c.total_order_product
from products p join (
select distinct(product_id) as product_id , sum(add_to_cart_order) over(partition by product_id) as total_order_product
from order_products) c
on p.product_id = c.product_id
order by total_order_product desc
LIMIT 10;

#Saving results to HDFS: 
INSERT OVERWRITE DIRECTORY "/HDFS/top_products_sold"
SELECT p.product_id, p.product_name ,c.total_order_product
from products p join (
select distinct(product_id) as product_id , sum(add_to_cart_order) over(partition by product_id) as total_order_product
from order_products) c
on p.product_id = c.product_id
order by total_order_product desc
LIMIT 10;

#Query 4: 
#Solution 1:
 select order_dow, count(*) from orders group by order_dow;

#Solution 2:

select distinct(order_dow) , count(order_dow) over(partition by order_dow) 
from orders ;

Query 5: 

Solution#1:
select order_dow, (total_orders/sum(total_orders) over()) * 100 from (select order_dow,count(order_id) as total_orders from orders group by order_dow)c;


Solution#2:(Cartesian product)
select distinct(order_dow) , ((count(*) over(partition by order_dow)) / c.total_count) * 100 as average_frequency 
from orders, (select count(*) as total_count from orders) c;



Query 6:

select product_name, total_count from products p inner join 
(select product_id ,count(add_to_cart_order) as total_count from order_products group by product_id order by total_count desc limit 10 ) c 
on p.product_id = c.product_id;


Query7: 
#Busiest Department
select p.department_id ,sum(s.product_count) as product_count_dept from products p inner join 
(select product_id, count(order_id) as product_count from order_products group by product_id order by product_count desc ) s
on p.product_id = s.product_id group by p.department_id order by product_count_dept desc limit 20;


#order_b Bucket table DDL
create table orders_b (order_id BIGINT, user_id INT,eval_set string, order_number decimal(10,1),order_dow int,order_hour_of_day int,days_since_prior_order STRING)  
clustered by (order_dow) into 7 buckets
row format serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
 with serdeproperties (
   "separatorChar" = ",",
   "quoteChar"     = "\""
 )
 STORED AS TEXTFILE ;


#insert data into bucketed table
INSERT OVERWRITE TABLE orders_b
select * from orders;

#Bucketed Query

select distinct(order_dow) , count(order_dow) over(partition by order_dow) 
from orders_b  order by order_dow;

Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 5.87 sec   HDFS Read: 1731900 HDFS Write: 250 SUCCESS
Stage-Stage-2: Map: 1  Reduce: 1   Cumulative CPU: 2.56 sec   HDFS Read: 4771 HDFS Write: 250 SUCCESS
Stage-Stage-3: Map: 1  Reduce: 1   Cumulative CPU: 2.74 sec   HDFS Read: 5724 HDFS Write: 220 SUCCESS
Total MapReduce CPU Time Spent: 11 seconds 170 msec

select distinct(order_dow) , count(order_dow) over(partition by order_dow) 
from orders_b  sort by order_dow;

MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 5.75 sec   HDFS Read: 1731465 HDFS Write: 250 SUCCESS
Stage-Stage-2: Map: 1  Reduce: 1   Cumulative CPU: 2.76 sec   HDFS Read: 5780 HDFS Write: 220 SUCCESS
Total MapReduce CPU Time Spent: 8 seconds 510 msec

select distinct(order_dow) , count(order_dow) over(partition by order_dow) 
from orders_b  cluster by order_dow;

MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 6.21 sec   HDFS Read: 1731465 HDFS Write: 250 SUCCESS
Stage-Stage-2: Map: 1  Reduce: 1   Cumulative CPU: 2.68 sec   HDFS Read: 5774 HDFS Write: 220 SUCCESS
Total MapReduce CPU Time Spent: 8 seconds 890 msec

select distinct(order_dow) , count(order_dow) over(partition by order_dow) 
from orders_b  distribute by order_dow;

MapReduce Jobs Launched:
Stage-Stage-1: Map: 1  Reduce: 1   Cumulative CPU: 6.55 sec   HDFS Read: 1731465 HDFS Write: 250 SUCCESS
Stage-Stage-2: Map: 1  Reduce: 1   Cumulative CPU: 2.87 sec   HDFS Read: 5774 HDFS Write: 220 SUCCESS
Total MapReduce CPU Time Spent: 9 seconds 420 msec

