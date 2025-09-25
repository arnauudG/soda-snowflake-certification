{{ config(severity='warn') }}

-- Data quality tests for the Soda Certification project (single statement)
-- Returns rows only when an issue is found. Any returned rows cause the test to fail.

with duplicate_customers as (
    select 'duplicate_customers' as issue,
           cast(email as varchar) as id,
           cast(count(*) as varchar) as info
    from {{ ref('stg_customers') }}
    where email is not null
    group by email
    having count(*) > 1
),

negative_product_price as (
    select 'negative_product_price' as issue,
           cast(product_id as varchar) as id,
           cast(price as varchar) as info
    from {{ ref('stg_products') }}
    where price < 0
),

negative_item_quantity as (
    select 'negative_item_quantity' as issue,
           cast(order_item_id as varchar) as id,
           cast(quantity as varchar) as info
    from {{ ref('stg_order_items') }}
    where quantity < 0
),

invalid_order_status as (
    select 'invalid_order_status' as issue,
           cast(order_id as varchar) as id,
           cast(order_status as varchar) as info
    from {{ ref('stg_orders') }}
    where order_status not in ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned')
),

future_order_date as (
    select 'future_order_date' as issue,
           cast(order_id as varchar) as id,
           cast(order_date as varchar) as info
    from {{ ref('stg_orders') }}
    where order_date > current_date()
),

missing_customer_info as (
    select 'missing_customer_info' as issue,
           cast(customer_id as varchar) as id,
           'missing_field' as info
    from {{ ref('stg_customers') }}
    where first_name is null or last_name is null or email is null
),

orphan_orders as (
    select 'orphan_order' as issue,
           cast(o.order_id as varchar) as id,
           cast(o.customer_id as varchar) as info
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
    where c.customer_id is null and o.customer_id is not null
),

orphan_order_items as (
    select 'orphan_order_item' as issue,
           cast(oi.order_item_id as varchar) as id,
           cast(oi.order_id as varchar) as info
    from {{ ref('stg_order_items') }} oi
    left join {{ ref('stg_orders') }} o on oi.order_id = o.order_id
    where o.order_id is null and oi.order_id is not null
),

order_amount_mismatch as (
    select 'order_amount_mismatch' as issue,
           cast(o.order_id as varchar) as id,
           cast(abs(o.total_amount - sum(oi.calculated_total_price)) as varchar) as info
    from {{ ref('stg_orders') }} o
    left join {{ ref('stg_order_items') }} oi on o.order_id = oi.order_id
    where o.total_amount > 0
    group by o.order_id, o.total_amount
    having abs(o.total_amount - sum(oi.calculated_total_price)) > 0.01
),

invalid_email_format as (
    select 'invalid_email' as issue,
           cast(customer_id as varchar) as id,
           cast(email as varchar) as info
    from {{ ref('stg_customers') }}
    where email is not null and email != '' and email not like '%@%'
)

select * from duplicate_customers
union all
select * from negative_product_price
union all
select * from negative_item_quantity
union all
select * from invalid_order_status
union all
select * from future_order_date
union all
select * from missing_customer_info
union all
select * from orphan_orders
union all
select * from orphan_order_items
union all
select * from order_amount_mismatch
union all
select * from invalid_email_format
