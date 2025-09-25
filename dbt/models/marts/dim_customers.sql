-- Customer dimension table (Gold layer)
-- Business-ready customer data with enriched attributes

with customers as (
    select * from {{ ref('stg_customers') }}
),

-- Add customer metrics
customer_metrics as (
    select 
        customer_id,
        count(*) as total_orders,
        sum(total_amount) as total_spent,
        avg(total_amount) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        count(distinct order_date) as active_days
    from {{ ref('stg_orders') }}
    where customer_id is not null
    group by customer_id
),

-- Add customer segmentation
customer_segmentation as (
    select 
        c.*,
        coalesce(cm.total_orders, 0) as total_orders,
        coalesce(cm.total_spent, 0) as total_spent,
        coalesce(cm.avg_order_value, 0) as avg_order_value,
        cm.first_order_date,
        cm.last_order_date,
        coalesce(cm.active_days, 0) as active_days,
        
        -- Customer lifetime value (CLV) calculation
        case 
            when cm.total_spent > 0 then
                round(cm.total_spent * 1.2, 2) -- Simple CLV calculation
            else 0
        end as estimated_clv,
        
        -- Customer recency (days since last order)
        case 
            when cm.last_order_date is not null then
                datediff('day', cm.last_order_date, current_date())
            else null
        end as days_since_last_order,
        
        -- Customer frequency (orders per month)
        case 
            when cm.first_order_date is not null then
                round(cm.total_orders / nullif(datediff('month', cm.first_order_date, current_date()), 0), 2)
            else 0
        end as orders_per_month,
        
        -- Customer monetary value tier
        case 
            when cm.total_spent >= 1000 then 'HIGH_VALUE'
            when cm.total_spent >= 500 then 'MEDIUM_VALUE'
            when cm.total_spent >= 100 then 'LOW_VALUE'
            else 'NO_PURCHASES'
        end as value_tier,
        
        -- Customer frequency tier
        case 
            when cm.total_orders >= 10 then 'FREQUENT'
            when cm.total_orders >= 5 then 'REGULAR'
            when cm.total_orders >= 1 then 'OCCASIONAL'
            else 'NEW'
        end as frequency_tier,
        
        -- Customer recency tier
        case 
            when cm.last_order_date is null then 'INACTIVE'
            when datediff('day', cm.last_order_date, current_date()) <= 30 then 'ACTIVE'
            when datediff('day', cm.last_order_date, current_date()) <= 90 then 'AT_RISK'
            else 'CHURNED'
        end as recency_tier,
        
        -- RFM Score (Recency, Frequency, Monetary)
        case 
            when cm.last_order_date is null then 1
            when datediff('day', cm.last_order_date, current_date()) <= 30 then 5
            when datediff('day', cm.last_order_date, current_date()) <= 60 then 4
            when datediff('day', cm.last_order_date, current_date()) <= 90 then 3
            when datediff('day', cm.last_order_date, current_date()) <= 180 then 2
            else 1
        end as recency_score,
        
        case 
            when cm.total_orders >= 20 then 5
            when cm.total_orders >= 10 then 4
            when cm.total_orders >= 5 then 3
            when cm.total_orders >= 2 then 2
            else 1
        end as frequency_score,
        
        case 
            when cm.total_spent >= 2000 then 5
            when cm.total_spent >= 1000 then 4
            when cm.total_spent >= 500 then 3
            when cm.total_spent >= 100 then 2
            else 1
        end as monetary_score
        
    from customers c
    left join customer_metrics cm on c.customer_id = cm.customer_id
)

select 
    customer_id,
    first_name,
    last_name,
    full_name,
    email,
    phone,
    address,
    city,
    state,
    zip_code,
    country,
    country_code,
    created_at,
    updated_at,
    ingestion_timestamp,
    
    -- Data quality fields
    has_missing_email,
    has_missing_phone,
    has_missing_name,
    data_quality_score,
    
    -- Customer metrics
    total_orders,
    total_spent,
    avg_order_value,
    first_order_date,
    last_order_date,
    active_days,
    estimated_clv,
    days_since_last_order,
    orders_per_month,
    
    -- Segmentation
    value_tier,
    frequency_tier,
    recency_tier,
    recency_score,
    frequency_score,
    monetary_score,
    
    -- RFM Segment
    concat(recency_score, frequency_score, monetary_score) as rfm_segment,
    
    -- Customer status
    case 
        when recency_tier = 'ACTIVE' and frequency_tier in ('FREQUENT', 'REGULAR') and value_tier in ('HIGH_VALUE', 'MEDIUM_VALUE') then 'CHAMPION'
        when recency_tier = 'ACTIVE' and frequency_tier = 'FREQUENT' then 'LOYAL_CUSTOMER'
        when recency_tier = 'ACTIVE' and value_tier = 'HIGH_VALUE' then 'BIG_SPENDER'
        when recency_tier = 'AT_RISK' then 'AT_RISK'
        when recency_tier = 'CHURNED' then 'CHURNED'
        when frequency_tier = 'NEW' then 'NEW_CUSTOMER'
        else 'POTENTIAL'
    end as customer_status,
    
    -- Data quality flags for business use
    case 
        when has_missing_email or has_missing_phone then 'INCOMPLETE_PROFILE'
        when data_quality_score < 50 then 'POOR_DATA_QUALITY'
        else 'GOOD_DATA_QUALITY'
    end as profile_quality_status
from customer_segmentation
