USE uber_case_study;

/* Identifying Duplicate record */

-- Identifying duplicate record from rides table
select ride_id, user_id, driver_id, city, ride_type
,booking_time, status, payment_mode, fare_amount, count(*) as cnt
from rides
group by ride_id, user_id, driver_id, city, ride_type
,booking_time, status, payment_mode, fare_amount
having count(*) > 1;

-- Identifying  duplicate record from drivers table
select driver_id, city, joining_date, rating, total_completed_rides, count(*) as cnt
from drivers
group by driver_id, city, joining_date, rating, total_completed_rides
having count(*) > 1;

/*  Removing Duplicate records */

-- Removing duplicate record from riders table
delete from rides
where id in (
	select id from
		(select id
		,row_number() over(partition by ride_id, user_id, driver_id, city, ride_type
		,booking_time, status, payment_mode, fare_amount) as rn
		from rides) x
where rn > 1);

-- Removing duplicate record from drivers table
delete from drivers
where id in (
	select id from
		(select *
		,row_number() over(partition by driver_id, city, joining_date, rating, total_completed_rides) as rn
		from drivers) x
where rn > 1);

set SQL_SAFE_UPDATES=0;

-- cleaning date formats
UPDATE rides 
SET booking_time = replace(booking_time, '/', '-');

UPDATE rides 
SET booking_time = STR_TO_DATE(booking_time, '%Y-%m-%d %H:%i:%s');

ALTER TABLE rides 
MODIFY COLUMN booking_time DATETIME,
MODIFY COLUMN start_time DATETIME, 
MODIFY COLUMN end_time DATETIME;

ALTER TABLE payments 
MODIFY COLUMN payout_time DATETIME;

/* Key Metrics */
-- Ride completion Rate
select 
round(sum(case when status = 'completed' then 1 else 0 end) * 100/ count(*),2) as ride_completion_rate
from rides;

-- User/Driver Cancellation Rate
select 
round(sum(case when status = 'canceled_driver' then 1 else 0 end) * 100/ count(*),2) as driver_cancellation_rate
,round(sum(case when status = 'canceled_user' then 1 else 0 end) * 100/ count(*),2) as user_cancellation_rate 
from rides;

-- Payout delay %
select 
round(sum(case when payout_status = 'delayed' then 1 else 0 end) *100 / count(*),2) as payment_delay_percent
from rides r
inner join payments p
on r.ride_id = p.ride_id
where status = 'completed';

-- Payment Failure Rate 
select 
round(sum(case when payment_status = 'failed' then 1 else 0 end) *100 / count(*),2) as payment_failure_rate
from rides r
inner join payments p
on r.ride_id = p.ride_id
where r.status = 'completed';

/* Analysis Approaches */

-- Ride completion Rate by Ride_type
select ride_type
,round(sum(case when status = 'completed' then 1 else 0 end) * 100/ count(*),2) as ride_completion_rate
from rides
group by ride_type
order by ride_completion_rate desc;

/* we can see that the Auto ride have a completion rate of 84% and Mini rides 83.3% compared to Prime rides
at 87.04%. This gap indicates operational inefficiencies that may impact customer satisfaction.
We recommend that drivers receive timely payout and transparent fare breakdown */

-- User/Driver Cancellation Rate by city, ride_type
select city, ride_type
, round(sum(case when status = 'canceled_user' then 1 else 0 end) * 100/ count(*),2) as user_cancellation_rate
, round(sum(case when status = 'canceled_driver' then 1 else 0 end) * 100/ count(*),2) as driver_cancellation_rate
from rides
group by city, ride_type
order by city, ride_type;

/* Mumbai shows the highest cancellation rate with 16.13% driver cancellation in Auto rides 12.77% in Prime ride and 10.14% in Mini ride. 
Delhi has 13.73% user cancellation rate in Mini ride and 10.20% in Auto ride while Bangalore we can see 7.69% cancellation rate in Mini rides.
Investigate Driver issue in Mumbai & Delhi (payout delays, incententive structure, etc)
to reduce cancellation and address user side issues in Bangalore by analyzing (pricing, longer wait or UI experience)*/

-- Payment Failure Rate by payment mode
select payment_mode
, round(sum(case when payment_status = 'failed' then 1 else 0 end) *100 / count(*),2) as payment_failure_rate
from rides r
inner join payments p
on r.ride_id = p.ride_id
where r.status = 'completed'
group by payment_mode
order by payment_failure_rate desc;

/* Gpay shows 13.04% payment_failure rate which is significantly above other modes while the 
Cash payments have a failure rate of 9.15%, which is relatively moderate but still higher than card transactions of 8.33% 
meaning they are more reliable in terms of transaction success, strengthening digital payment infrastructure */

-- Driver Payout Delay Analysis 
with cte as(
select driver_id, ride_type, status as ride_status, payment_status, payout_status 
,(timestampdiff(minute, end_time, payout_time)/60) as total_payout_hr
from rides r
inner join payments p
on r.ride_id = p.ride_id
where status = 'completed'
),
cte_2 as
(select driver_id, ride_type, ride_status, payment_status, payout_status 
, round(total_payout_hr/ 24,2) as payout_delay_days 
from cte)
select payment_status, payout_status, count(*) as no_of_drivers
, coalesce(round(avg(payout_delay_days),2),'still delay') as avg_payout_delay_days
from cte_2 
group by payment_status, payout_status;

/*Our analysis shows that payouts processed beyond 24 hours after ride completion are delayed. 
Such delays negatively affect driver experience and may 
encourage drivers to bypass the app, asking customers to pay them directly
We recommend ensuring payouts are completed within 24 hours to improve satisfaction and operational efficiency.*/

-- Payment success by payment mode
select payment_mode
, round(sum(case when payment_status = 'success' then 1 else 0 end) *100 / count(*),2) as payment_success_rate
from rides r
inner join payments p
on r.ride_id = p.ride_id
group by payment_mode;

-- Quarterly Completion Trend Analysis (RCA)
with summary as
(select month(booking_time) as month
, quarter(booking_time) as quarter
, count(*) as total_request 
,round(sum(case when status = 'completed' then 1 else 0 end) * 100/ count(*),2) as completion_rate
,(count(*) * round(sum(case when status = 'completed' then 1 else 0 end) / count(*),2)) as completed_rides
from rides
group by quarter(booking_time), month(booking_time)
order by quarter(booking_time), month(booking_time)),
quarter_bounds as
(select quarter
,min(month) as min_month
,max(month) as max_month
from summary
group by quarter)
select qb.quarter
,round(((max_r.completed_rides - min_r.completed_rides) *100 / min_r.completed_rides),2) as drop_rise_percent
from quarter_bounds qb
join summary min_r
on min_r.quarter = qb.quarter and min_r.month = qb.min_month
join summary max_r
on max_r.quarter = qb.quarter and max_r.month = qb.max_month;

/* We can see that the Q3 drop is overall decline in completed rides is mainly due to Q3
 cancellations tied to digital payment issues. Fixing payout delays, incentivizing driver compliance, 
 and improving customer flexibility are the most effective ways to restore growth. */






