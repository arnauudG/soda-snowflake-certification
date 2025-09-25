-- Orders fact table (Gold layer)
-- Business-ready order data with all related dimensions

with orders as (
    select * from {{ ref('stg_orders') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

-- Aggregate order items to order level
order_item_aggregates as (
    select 
        oi.order_id,
        count(*) as total_items,
        sum(oi.quantity) as total_quantity,
        sum(oi.calculated_total_price) as calculated_order_total,
        sum(oi.discount_amount) as total_discount_amount,
        avg(oi.discount_percent) as avg_discount_percent,
        count(distinct oi.product_id) as unique_products,
        count(distinct p.category) as unique_categories
    from order_items oi
    left join products p on oi.product_id = p.product_id
    where oi.order_id is not null
    group by oi.order_id
),

-- Join all data together
enriched_orders as (
    select 
        o.order_id,
        o.customer_id,
        o.order_date,
        o.order_status,
        o.status_category,
        o.total_amount as order_total_amount,
        o.currency,
        o.shipping_address,
        o.payment_method,
        o.payment_category,
        o.created_at,
        o.updated_at,
        o.ingestion_timestamp,
        
        -- Customer information
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        c.full_name as customer_full_name,
        c.email as customer_email,
        c.city as customer_city,
        c.state as customer_state,
        c.country as customer_country,
        c.data_quality_score as customer_data_quality_score,
        
        -- Order item aggregates
        coalesce(oia.total_items, 0) as total_items,
        coalesce(oia.total_quantity, 0) as total_quantity,
        coalesce(oia.calculated_order_total, 0) as calculated_order_total,
        coalesce(oia.total_discount_amount, 0) as total_discount_amount,
        coalesce(oia.avg_discount_percent, 0) as avg_discount_percent,
        coalesce(oia.unique_products, 0) as unique_products,
        coalesce(oia.unique_categories, 0) as unique_categories,
        
        -- Order analysis fields
        o.order_value_tier,
        o.order_year,
        o.order_month,
        o.order_day_of_week,
        o.order_quarter,
        o.processing_days,
        
        -- Data quality flags
        o.has_invalid_customer,
        o.has_negative_amount,
        o.has_invalid_status,
        o.has_future_date,
        o.has_invalid_currency,
        o.data_quality_score as order_data_quality_score,
        
        -- Business logic flags
        case 
            when o.total_amount != coalesce(oia.calculated_order_total, 0) then true
            else false
        end as has_amount_mismatch,
        
        case 
            when o.total_amount > 0 and coalesce(oia.total_items, 0) = 0 then true
            else false
        end as has_orphaned_order,
        
        case 
            when o.order_status = 'delivered' and o.processing_days > 30 then true
            else false
        end as has_slow_delivery
        
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join order_item_aggregates oia on o.order_id = oia.order_id
)

select 
    order_id,
    customer_id,
    order_date,
    order_status,
    status_category,
    order_total_amount,
    calculated_order_total,
    currency,
    shipping_address,
    payment_method,
    payment_category,
    created_at,
    updated_at,
    ingestion_timestamp,
    
    -- Customer information
    customer_first_name,
    customer_last_name,
    customer_full_name,
    customer_email,
    customer_city,
    customer_state,
    customer_country,
    customer_data_quality_score,
    
    -- Order metrics
    total_items,
    total_quantity,
    total_discount_amount,
    avg_discount_percent,
    unique_products,
    unique_categories,
    
    -- Order analysis
    order_value_tier,
    order_year,
    order_month,
    order_day_of_week,
    order_quarter,
    processing_days,
    
    -- Data quality flags
    has_invalid_customer,
    has_negative_amount,
    has_invalid_status,
    has_future_date,
    has_invalid_currency,
    order_data_quality_score,
    has_amount_mismatch,
    has_orphaned_order,
    has_slow_delivery,
    
    -- Business metrics
    case 
        when order_total_amount > 0 then
            round((total_discount_amount / order_total_amount) * 100, 2)
        else 0
    end as discount_percentage,
    
    case 
        when total_items > 0 then
            round(order_total_amount / total_items, 2)
        else 0
    end as avg_item_value,
    
    case 
        when total_quantity > 0 then
            round(order_total_amount / total_quantity, 2)
        else 0
    end as avg_unit_value,
    
    -- Order complexity score
    case 
        when unique_categories >= 3 and total_items >= 5 then 'COMPLEX'
        when unique_categories >= 2 or total_items >= 3 then 'MODERATE'
        else 'SIMPLE'
    end as order_complexity,
    
    -- Overall data quality score
    case 
        when order_data_quality_score < 50 or customer_data_quality_score < 50 then 'POOR'
        when order_data_quality_score < 75 or customer_data_quality_score < 75 then 'FAIR'
        else 'GOOD'
    end as overall_data_quality
from enriched_orders
