CREATE OR REPLACE PROCEDURE `playground-411306.thelook_ecommerce.p_dm_daily_activity`()
BEGIN

 -- Create by : Nadya Fauziah
 -- Script    : call `playground-411306.thelook_ecommerce.p_dm_daily_activity`();
 -- Schedule  : 

DECLARE v_start_date datetime;
set v_start_date = DATETIME(CURRENT_TIMESTAMP(), 'Asia/Jakarta') ;

CREATE OR REPLACE TABLE `playground-411306.thelook_ecommerce.dm_daily_activity`
PARTITION BY order_date
CLUSTER BY order_id
AS

with base as(
  select distinct
    fo.order_date,
    fo.order_id,
    fo.user_id,
    fo.product_id,  
    dimp.product_category,
    dimp.product_name,
    dimp.product_brand,
    dimp.product_department,
    dimo.status,
    dimc.country_id,
    dimc.country_name,
    dimc.country_latitude,
    dimc.country_longitude,
    fo.qty,
    fo.sale_price,
    fo.sales_value,
    -- for initial the cycle
    1 as lifetime_cycle_sequence
  from `playground-411306.thelook_ecommerce.fact_orders` fo
  left join `playground-411306.thelook_ecommerce.dim_order` dimo
    on fo.order_id = dimo.order_id
  left join `playground-411306.thelook_ecommerce.dim_product` dimp
    on fo.product_id = dimp.product_id
  left join `playground-411306.thelook_ecommerce.dim_country` dimc
    on fo.country_id = dimc.country_id
  where true
  and fo.order_date >= '2024-04-01'
)
, cycle as(
  select distinct 
    order_date,
    user_id,
  from base
)
, cycle2 as(
  select * ,
    lag(order_date) over(partition by user_id order by order_date asc) as lag_order_date
  from cycle
)

select 
  * except(lifetime_cycle_sequence),
  case 
    -- will return the value of initial
    when lag_order_date is null then lifetime_cycle_sequence
    -- will return back to 1 if day diff > 10
    when date_diff(order_date, lag_order_date, day) >= 10 then 1
    -- will add 1 to cycle
    else lifetime_cycle_sequence+1
  end as lifetime_cycle_sequence,

  if(status = 'Complete',
    row_number() over(partition by status, user_id order by order_date asc), 
    0) as purchase_sequence,
    
from base
left join cycle2 using(user_id, order_date)
where true
-- and status = 'Complete'
-- order by user_id asc, order_date asc


;
END;
