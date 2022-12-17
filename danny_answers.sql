
#1)What is the total amount each customer spent at the restaurant?
SELECT customer_id,sum(price) as total_spent FROM sales s
join menu m on m.product_id=s.product_id
group by customer_id;

#2)How many days has each customer visited the restaurant?
select customer_id,count(distinct(order_date)) as total_visits from sales
group by customer_id;

#3)What was the first item from the menu purchased by each customer?
with cte1 as 
(SELECT s.*,m.product_name,m.price,
row_number()over(partition by customer_id) as rn1
FROM dannys_diner.sales s 
join menu m on s.product_id=m.product_id)
select customer_id,product_name as first_Item_purchased from cte1 where rn1=1;

#4)What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,count(product_id) as max_purchased_item FROM joined_table
group by product_id
order by max_purchased_item desc 
limit 1;

#5)Which item was the most popular for each customer?
with cte2 as 
(with cte1 as
(SELECT product_id,product_name,customer_id,count(product_id) as most_popular_item
FROM joined_table
group by product_id,customer_id
order by customer_id)
select *,dense_rank()over(partition by customer_id order by most_popular_item desc) as drnk
from cte1)
select product_id,product_name,customer_id,most_popular_item from cte2 where drnk=1;

#6)Which item was purchased first by the customer after they became a member?

with cte1 as 
(SELECT *,row_number()over(partition by customer_id) as rn FROM dannys_diner.fullinfotable
where mem="YES")
select customer_id,product_name as first_item_purchased_aftermember from cte1 where rn=1;


#7)Which item was purchased just before the customer became a member?

 with cte2 as 
 (with cte1 as (SELECT * FROM dannys_diner.fullinfo_tble where rnk=0 and customer_id in("A","B"))
 select customer_id,product_name,order_date,dense_rank() over (partition by customer_id order by order_date desc) as drnk 
 from cte1)
 select customer_id,product_name as last_purchased_beforemember from cte2 where drnk=1;
 
 #8)What is the total items and amount spent for each member before they became a member?
 with cte1 as
(SELECT s.*,m.product_name,m.price,
case
 when(customer_id="A" and order_date>='2021-01-07') then "YES"
 when(customer_id="B" and order_date>='2021-01-09') then "YES"
 else "NO"
 end as mem
FROM sales s
 join menu m on s.product_id=m.product_id)
 select customer_id,sum(price) as total_spent
 from cte1 where mem="NO" and customer_id in ("A","B")
 group by customer_id;
 
#9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
#how many points would each customer have?

SELECT customer_id,
sum(case when product_name="sushi" then (2*10*price)  
     else (1*10*price) end)as points
FROM sales s join menu m on s.product_id=m.product_id
group by customer_id;

#10)In the first week after a customer joins the program (including their join date) 
#they earn 2x points on all items,
# not just sushi - how many points do customer A and B have at the end of January?

WITH dates_cte AS 
(
 SELECT *, 
  DATE_ADD(join_date,interval 6 day) AS valid_date, 
  last_day('2021-01-07') AS last_date
 FROM members AS m
)
SELECT d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
  ELSE 10 * m.price
  END) AS points
FROM dates_cte AS d
JOIN sales AS s
 ON d.customer_id = s.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id