-- Customer dimension table (Gold layer)
-- Business-ready customer data with enriched attributes

with customers as (
    select * from {{ ref('stg_customers') }}
),

-- Add customer metrics
customer_metrics as (
    select 
        CUSTOMER_ID,
        count(*) as TOTAL_ORDERS,
        sum(TOTAL_AMOUNT) as TOTAL_SPENT,
        avg(TOTAL_AMOUNT) as AVG_ORDER_VALUE,
        min(ORDER_DATE) as FIRST_ORDER_DATE,
        max(ORDER_DATE) as LAST_ORDER_DATE,
        count(distinct ORDER_DATE) as ACTIVE_DAYS
    from {{ ref('stg_orders') }}
    where CUSTOMER_ID is not null
    group by CUSTOMER_ID
),

-- Add customer segmentation
customer_segmentation as (
    select 
        c.*,
        coalesce(cm.TOTAL_ORDERS, 0) as TOTAL_ORDERS,
        coalesce(cm.TOTAL_SPENT, 0) as TOTAL_SPENT,
        coalesce(cm.AVG_ORDER_VALUE, 0) as AVG_ORDER_VALUE,
        cm.FIRST_ORDER_DATE,
        cm.LAST_ORDER_DATE,
        coalesce(cm.ACTIVE_DAYS, 0) as ACTIVE_DAYS,
        
        -- Customer lifetime value (CLV) calculation
        case 
            when cm.TOTAL_SPENT > 0 then
                round(cm.TOTAL_SPENT * 1.2, 2) -- Simple CLV calculation
            else 0
        end as ESTIMATED_CLV,
        
        -- Customer recency (days since last order)
        case 
            when cm.LAST_ORDER_DATE is not null then
                datediff('day', cm.LAST_ORDER_DATE, current_date())
            else null
        end as DAYS_SINCE_LAST_ORDER,
        
        -- Customer frequency (orders per month)
        case 
            when cm.FIRST_ORDER_DATE is not null then
                round(cm.TOTAL_ORDERS / nullif(datediff('month', cm.FIRST_ORDER_DATE, current_date()), 0), 2)
            else 0
        end as ORDERS_PER_MONTH,
        
        -- Customer monetary value tier
        case 
            when cm.TOTAL_SPENT >= 1000 then 'HIGH_VALUE'
            when cm.TOTAL_SPENT >= 500 then 'MEDIUM_VALUE'
            when cm.TOTAL_SPENT >= 100 then 'LOW_VALUE'
            else 'NO_PURCHASES'
        end as VALUE_TIER,
        
        -- Customer frequency tier
        case 
            when cm.TOTAL_ORDERS >= 10 then 'FREQUENT'
            when cm.TOTAL_ORDERS >= 5 then 'REGULAR'
            when cm.TOTAL_ORDERS >= 1 then 'OCCASIONAL'
            else 'NEW'
        end as FREQUENCY_TIER,
        
        -- Customer recency tier
        case 
            when cm.LAST_ORDER_DATE is null then 'INACTIVE'
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 30 then 'ACTIVE'
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 90 then 'AT_RISK'
            else 'CHURNED'
        end as RECENCY_TIER,
        
        -- RFM Score (Recency, Frequency, Monetary)
        case 
            when cm.LAST_ORDER_DATE is null then 1
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 30 then 5
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 60 then 4
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 90 then 3
            when datediff('day', cm.LAST_ORDER_DATE, current_date()) <= 180 then 2
            else 1
        end as RECENCY_SCORE,
        
        case 
            when cm.TOTAL_ORDERS >= 20 then 5
            when cm.TOTAL_ORDERS >= 10 then 4
            when cm.TOTAL_ORDERS >= 5 then 3
            when cm.TOTAL_ORDERS >= 2 then 2
            else 1
        end as FREQUENCY_SCORE,
        
        case 
            when cm.TOTAL_SPENT >= 2000 then 5
            when cm.TOTAL_SPENT >= 1000 then 4
            when cm.TOTAL_SPENT >= 500 then 3
            when cm.TOTAL_SPENT >= 100 then 2
            else 1
        end as MONETARY_SCORE
        
    from customers c
    left join customer_metrics cm on c.CUSTOMER_ID = cm.CUSTOMER_ID
)

select 
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    FULL_NAME,
    EMAIL,
    PHONE,
    ADDRESS,
    CITY,
    STATE,
    ZIP_CODE,
    COUNTRY,
    COUNTRY_CODE,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    
    -- Data quality fields
    HAS_MISSING_EMAIL,
    HAS_MISSING_PHONE,
    HAS_MISSING_NAME,
    DATA_QUALITY_SCORE,
    
    -- Customer metrics
    TOTAL_ORDERS,
    TOTAL_SPENT,
    AVG_ORDER_VALUE,
    FIRST_ORDER_DATE,
    LAST_ORDER_DATE,
    ACTIVE_DAYS,
    ESTIMATED_CLV,
    DAYS_SINCE_LAST_ORDER,
    ORDERS_PER_MONTH,
    
    -- Segmentation
    VALUE_TIER,
    FREQUENCY_TIER,
    RECENCY_TIER,
    RECENCY_SCORE,
    FREQUENCY_SCORE,
    MONETARY_SCORE,
    
    -- RFM Segment
    concat(RECENCY_SCORE, FREQUENCY_SCORE, MONETARY_SCORE) as RFM_SEGMENT,
    
    -- Customer status
    case 
        when RECENCY_TIER = 'ACTIVE' and FREQUENCY_TIER in ('FREQUENT', 'REGULAR') and VALUE_TIER in ('HIGH_VALUE', 'MEDIUM_VALUE') then 'CHAMPION'
        when RECENCY_TIER = 'ACTIVE' and FREQUENCY_TIER = 'FREQUENT' then 'LOYAL_CUSTOMER'
        when RECENCY_TIER = 'ACTIVE' and VALUE_TIER = 'HIGH_VALUE' then 'BIG_SPENDER'
        when RECENCY_TIER = 'AT_RISK' then 'AT_RISK'
        when RECENCY_TIER = 'CHURNED' then 'CHURNED'
        when FREQUENCY_TIER = 'NEW' then 'NEW_CUSTOMER'
        else 'POTENTIAL'
    end as CUSTOMER_STATUS,
    
    -- Data quality flags for business use
    case 
        when HAS_MISSING_EMAIL or HAS_MISSING_PHONE then 'INCOMPLETE_PROFILE'
        when DATA_QUALITY_SCORE < 50 then 'POOR_DATA_QUALITY'
        else 'GOOD_DATA_QUALITY'
    end as PROFILE_QUALITY_STATUS
from customer_segmentation
