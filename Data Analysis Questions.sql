-- How many customers has Foodie-Fi ever had?
select count(distinct customer_id)
from subscriptions

-- What is the monthly distribution of trial plan start_date values for our dataset - 
-- use the start of the month as the group by value
/*
DATEDIFF(month, 0, start_date): Calculates the number of months between a fixed date (0, which is 1900-01-01) and start_date.
DATEADD(month, DATEDIFF(month, 0, start_date), 0): Adds the calculated months to 1900-01-01, effectively setting start_date to the first day of its month.*/
select Cast(DATEADD(month, DATEDIFF(month, 0, start_date), 0) as date) AS start_of_month, 
count(distinct customer_id) as number_of_free_trials
from subscriptions s
join plans p
on s.plan_id = p.plan_id
where plan_name = 'trial'
group by DATEADD(month, DATEDIFF(month, 0, start_date), 0)

/*What plan start_date values occur after the year 2020 for our dataset? 
Show the breakdown by count of events for each plan_name */
select plan_name,count(plan_name) as number_of_occurances_after_2022
from subscriptions s
join plans p
on s.plan_id = p.plan_id
where YEAR(start_date) > 2020
group by plan_name 

/*What is the customer count and percentage of customers who have churned 
rounded to 1 decimal place? */
select count(s.customer_id) as total_churn, 
round(count(s.customer_id) * 100.0 / (select count(distinct customer_id) from subscriptions),1) as percentage_of_churn
from subscriptions s
join plans p
on s.plan_id = p.plan_id
where plan_name = 'churn'

/*How many customers have churned straight after their initial free trial 
- what percentage is this rounded to the nearest whole number? */

create view customer_plans_vw as (
	select customer_id, start_date,plan_name, 
	lead(plan_name) over(partition by customer_id order by start_date) as next_plan
	from subscriptions s
	join plans p
	on s.plan_id = p.plan_id
)
use week3
select round(count(*) * 100.0 / 
(select count(distinct customer_id) from subscriptions),0)
from customer_plans_vw
where plan_name = 'trial' and next_plan = 'churn'


-- What is the number and percentage of customer plans after their initial free trial?
select next_plan, count(customer_id) as number_of_customers,
count(customer_id) * 100.00 / (select count(distinct customer_id) from subscriptions)
from customer_plans_vw
where plan_name = 'trial'
group by next_plan
order by number_of_customers desc

-- What is the customer count and percentage breakdown of all 
-- 5 plan_name values at 2020-12-31?
select plan_name, count(customer_id) as customer_count,
round(count(customer_id) * 100.0 / (select count(distinct customer_id) from subscriptions),2)
from (
	select customer_id, plan_name,start_date, row_number() over(partition by customer_id order by start_date desc) as rn
	from subscriptions s 
	join plans p 
	on s.plan_id = p.plan_id
	where start_date <= '2020-12-31'
) sub
where rn = 1
group by plan_name

-- How many customers have upgraded to an annual plan in 2020?
select count(*)
from customer_plans_vw
where YEAR(start_date) = 2020 and plan_name = 'pro annual'

-- How many days on average does it take for a customer 
-- to an annual plan from the day they join Foodie-Fi?
select avg(cast(DATEDIFF(day, start_date, next_date) as float)) as days_to_upgrade
from(
	select *, lead(start_date) over(partition by customer_id order by start_date) as next_date
	from subscriptions
	where plan_id in (0,3)
) tmp


-- Can you further breakdown this average value into 
-- 30 day periods (i.e. 0-30 days, 31-60 days etc)
with days_to_upgrade_cte as (
	select cast(DATEDIFF(day, start_date, next_date) as float) as days_to_upgrade
	from(
		select *, lead(start_date) over(partition by customer_id order by start_date) as next_date
		from subscriptions
		where plan_id in (0,3)
	) tmp
),
days_to_upgrade_broken as( 
SELECT days_to_upgrade,
    CASE 
        WHEN days_to_upgrade BETWEEN 0 AND 30 THEN '1-30'
        WHEN days_to_upgrade BETWEEN 31 AND 60 THEN '31-60'
        WHEN days_to_upgrade BETWEEN 61 AND 90 THEN '61-90'
        WHEN days_to_upgrade BETWEEN 91 AND 120 THEN '91-120'
        WHEN days_to_upgrade BETWEEN 121 AND 150 THEN '121-150'
        WHEN days_to_upgrade BETWEEN 151 AND 180 THEN '151-180'
        WHEN days_to_upgrade BETWEEN 181 AND 210 THEN '181-210'
        WHEN days_to_upgrade BETWEEN 211 AND 240 THEN '211-240'
        WHEN days_to_upgrade BETWEEN 241 AND 270 THEN '241-270'
        WHEN days_to_upgrade BETWEEN 271 AND 300 THEN '271-300'
        WHEN days_to_upgrade BETWEEN 301 AND 330 THEN '301-330'
        WHEN days_to_upgrade BETWEEN 331 AND 360 THEN '331-360'
	end as period
from days_to_upgrade_cte
where days_to_upgrade is not null
)

select period, count(*)
from days_to_upgrade_broken
group by period
order by CASE
	    WHEN period = '1-30' THEN 1
        WHEN period = '31-60' THEN 2
        WHEN period = '61-90' THEN 3
        WHEN period = '91-120' THEN 4
        WHEN period = '121-150' THEN 5
        WHEN period = '151-180' THEN 6
        WHEN period = '181-210' THEN 7
        WHEN period = '211-240' THEN 8
        WHEN period = '241-270' THEN 9
        WHEN period = '271-300' THEN 10
        WHEN period = '301-330' THEN 11
        WHEN period = '331-360' THEN 12
		END

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select count(distinct customer_id) as total_downgraded 
from customer_plans_vw
where YEAR(start_date) = 2020 and plan_name = 'pro monthly' and next_plan = 'basic monthly'