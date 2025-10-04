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
        oi.ORDER_ID,
        count(*) as TOTAL_ITEMS,
        sum(oi.QUANTITY) as TOTAL_QUANTITY,
        sum(oi.CALCULATED_TOTAL_PRICE) as CALCULATED_ORDER_TOTAL,
        sum(oi.DISCOUNT_AMOUNT) as TOTAL_DISCOUNT_AMOUNT,
        avg(oi.DISCOUNT_PERCENT) as AVG_DISCOUNT_PERCENT,
        count(distinct oi.PRODUCT_ID) as UNIQUE_PRODUCTS,
        count(distinct p.CATEGORY) as UNIQUE_CATEGORIES
    from order_items oi
    left join products p on oi.PRODUCT_ID = p.PRODUCT_ID
    where oi.ORDER_ID is not null
    group by oi.ORDER_ID
),

-- Join all data together
enriched_orders as (
    select 
        o.ORDER_ID,
        o.CUSTOMER_ID,
        o.ORDER_DATE,
        o.ORDER_STATUS,
        o.STATUS_CATEGORY,
        o.TOTAL_AMOUNT as ORDER_TOTAL_AMOUNT,
        o.CURRENCY,
        o.SHIPPING_ADDRESS,
        o.PAYMENT_METHOD,
        o.PAYMENT_CATEGORY,
        o.CREATED_AT,
        o.UPDATED_AT,
        o.INGESTION_TIMESTAMP,
        
        -- Customer information
        c.FIRST_NAME as CUSTOMER_FIRST_NAME,
        c.LAST_NAME as CUSTOMER_LAST_NAME,
        c.FULL_NAME as CUSTOMER_FULL_NAME,
        c.EMAIL as CUSTOMER_EMAIL,
        c.CITY as CUSTOMER_CITY,
        c.STATE as CUSTOMER_STATE,
        c.COUNTRY as CUSTOMER_COUNTRY,
        c.DATA_QUALITY_SCORE as CUSTOMER_DATA_QUALITY_SCORE,
        
        -- Order item aggregates
        coalesce(oia.TOTAL_ITEMS, 0) as TOTAL_ITEMS,
        coalesce(oia.TOTAL_QUANTITY, 0) as TOTAL_QUANTITY,
        coalesce(oia.CALCULATED_ORDER_TOTAL, 0) as CALCULATED_ORDER_TOTAL,
        coalesce(oia.TOTAL_DISCOUNT_AMOUNT, 0) as TOTAL_DISCOUNT_AMOUNT,
        coalesce(oia.AVG_DISCOUNT_PERCENT, 0) as AVG_DISCOUNT_PERCENT,
        coalesce(oia.UNIQUE_PRODUCTS, 0) as UNIQUE_PRODUCTS,
        coalesce(oia.UNIQUE_CATEGORIES, 0) as UNIQUE_CATEGORIES,
        
        -- Order analysis fields
        o.ORDER_VALUE_TIER,
        o.ORDER_YEAR,
        o.ORDER_MONTH,
        o.ORDER_DAY_OF_WEEK,
        o.ORDER_QUARTER,
        o.PROCESSING_DAYS,
        
        -- Data quality flags
        o.HAS_INVALID_CUSTOMER,
        o.HAS_NEGATIVE_AMOUNT,
        o.HAS_INVALID_STATUS,
        o.HAS_FUTURE_DATE,
        o.HAS_INVALID_CURRENCY,
        o.DATA_QUALITY_SCORE as ORDER_DATA_QUALITY_SCORE,
        
        -- Business logic flags
        case 
            when o.TOTAL_AMOUNT != coalesce(oia.CALCULATED_ORDER_TOTAL, 0) then true
            else false
        end as HAS_AMOUNT_MISMATCH,
        
        case 
            when o.TOTAL_AMOUNT > 0 and coalesce(oia.TOTAL_ITEMS, 0) = 0 then true
            else false
        end as HAS_ORPHANED_ORDER,
        
        case 
            when o.ORDER_STATUS = 'delivered' and o.PROCESSING_DAYS > 30 then true
            else false
        end as HAS_SLOW_DELIVERY
        
    from orders o
    left join customers c on o.CUSTOMER_ID = c.CUSTOMER_ID
    left join order_item_aggregates oia on o.ORDER_ID = oia.ORDER_ID
)

select 
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_DATE,
    ORDER_STATUS,
    STATUS_CATEGORY,
    ORDER_TOTAL_AMOUNT,
    CALCULATED_ORDER_TOTAL,
    CURRENCY,
    SHIPPING_ADDRESS,
    PAYMENT_METHOD,
    PAYMENT_CATEGORY,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    
    -- Customer information
    CUSTOMER_FIRST_NAME,
    CUSTOMER_LAST_NAME,
    CUSTOMER_FULL_NAME,
    CUSTOMER_EMAIL,
    CUSTOMER_CITY,
    CUSTOMER_STATE,
    CUSTOMER_COUNTRY,
    CUSTOMER_DATA_QUALITY_SCORE,
    
    -- Order metrics
    TOTAL_ITEMS,
    TOTAL_QUANTITY,
    TOTAL_DISCOUNT_AMOUNT,
    AVG_DISCOUNT_PERCENT,
    UNIQUE_PRODUCTS,
    UNIQUE_CATEGORIES,
    
    -- Order analysis
    ORDER_VALUE_TIER,
    ORDER_YEAR,
    ORDER_MONTH,
    ORDER_DAY_OF_WEEK,
    ORDER_QUARTER,
    PROCESSING_DAYS,
    
    -- Data quality flags
    HAS_INVALID_CUSTOMER,
    HAS_NEGATIVE_AMOUNT,
    HAS_INVALID_STATUS,
    HAS_FUTURE_DATE,
    HAS_INVALID_CURRENCY,
    ORDER_DATA_QUALITY_SCORE,
    HAS_AMOUNT_MISMATCH,
    HAS_ORPHANED_ORDER,
    HAS_SLOW_DELIVERY,
    
    -- Business metrics
    case 
        when ORDER_TOTAL_AMOUNT > 0 then
            round((TOTAL_DISCOUNT_AMOUNT / ORDER_TOTAL_AMOUNT) * 100, 2)
        else 0
    end as DISCOUNT_PERCENTAGE,
    
    case 
        when TOTAL_ITEMS > 0 then
            round(ORDER_TOTAL_AMOUNT / TOTAL_ITEMS, 2)
        else 0
    end as AVG_ITEM_VALUE,
    
    case 
        when TOTAL_QUANTITY > 0 then
            round(ORDER_TOTAL_AMOUNT / TOTAL_QUANTITY, 2)
        else 0
    end as AVG_UNIT_VALUE,
    
    -- Order complexity score
    case 
        when UNIQUE_CATEGORIES >= 3 and TOTAL_ITEMS >= 5 then 'COMPLEX'
        when UNIQUE_CATEGORIES >= 2 or TOTAL_ITEMS >= 3 then 'MODERATE'
        else 'SIMPLE'
    end as ORDER_COMPLEXITY,
    
    -- Overall data quality score
    case 
        when ORDER_DATA_QUALITY_SCORE < 50 or CUSTOMER_DATA_QUALITY_SCORE < 50 then 'POOR'
        when ORDER_DATA_QUALITY_SCORE < 75 or CUSTOMER_DATA_QUALITY_SCORE < 75 then 'FAIR'
        else 'GOOD'
    end as OVERALL_DATA_QUALITY
from enriched_orders
