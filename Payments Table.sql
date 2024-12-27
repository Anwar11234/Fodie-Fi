create or alter view next_plans_vw as
SELECT customer_id,p.plan_id, start_date, plan_name, price, 
	LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
FROM subscriptions s
join plans p
on s.plan_id = p.plan_id
WHERE YEAR(start_date) = 2020 AND plan_name != 'trial'

create view monthly_payments_vw as
WITH DateSeries AS (
    SELECT 
        customer_id, 
        plan_id, 
        plan_name, 
        start_date AS payment_date,
        price AS amount,
        COALESCE(DATEADD(DAY, -1, next_date), '2020-12-31') AS end_date
    FROM next_plans_vw
    UNION ALL
    SELECT 
        ds.customer_id, 
        ds.plan_id, 
        ds.plan_name, 
        DATEADD(MONTH, 1, ds.payment_date) AS payment_date,
        ds.amount,
        ds.end_date
    FROM DateSeries ds
    WHERE DATEADD(MONTH, 1, ds.payment_date) <= ds.end_date
)

SELECT 
    customer_id, 
    plan_id, 
    plan_name, 
    payment_date, 
    amount
FROM DateSeries
where plan_id in (1,2)

create or alter view all_payments as
select * from monthly_payments_vw
UNION ALL
SELECT 
    customer_id, 
    p.plan_id as plan_id, 
    plan_name, 
    start_date AS payment_date, 
    price AS amount
FROM 
subscriptions s
join plans p
on s.plan_id = p.plan_id
WHERE p.plan_id = 3


select *, ROW_NUMBER() over(partition by customer_id order by payment_date) as payment_order
from (
	select customer_id,
        plan_id,
        plan_name,
        payment_date, 
		case when LAG(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY payment_date) = 1 
                AND plan_id IN (2, 3) AND
			DATEADD(month, 1,LAG(payment_date, 1) OVER (PARTITION BY customer_id ORDER BY payment_date)) > payment_date
			then amount - 9.90
			else amount end as amount
	from all_payments
) subquery