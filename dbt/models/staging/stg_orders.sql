-- Staging model for orders (Silver layer)
-- Cleans and standardizes order data from raw layer
-- Optimized for large dataset (20,000+ orders)

{{ config(
    materialized='table',
    transient=false
) }}

with source_data as (
    select * from {{ source('raw', 'ORDERS') }}
),

cleaned_orders as (
    select
        ORDER_ID,
        -- Clean customer_id
        case 
            when CUSTOMER_ID like 'INVALID%' then null
            else CUSTOMER_ID
        end as CUSTOMER_ID,
        -- Clean order date
        case 
            when ORDER_DATE > current_date() then null
            else ORDER_DATE
        end as ORDER_DATE,
        -- Clean order status
        case 
            when ORDER_STATUS in ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned') 
            then ORDER_STATUS
            else 'unknown'
        end as ORDER_STATUS,
        -- Clean total amount (ensure positive values)
        case 
            when TOTAL_AMOUNT < 0 then null
            when TOTAL_AMOUNT = 0 then null
            else TOTAL_AMOUNT
        end as TOTAL_AMOUNT,
        -- Standardize currency
        case 
            when CURRENCY in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then CURRENCY
            else 'USD'
        end as CURRENCY,
        -- Clean shipping address
        trim(SHIPPING_ADDRESS) as SHIPPING_ADDRESS,
        -- Clean payment method
        case 
            when PAYMENT_METHOD in ('credit_card', 'debit_card', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer')
            then PAYMENT_METHOD
            when PAYMENT_METHOD is null or PAYMENT_METHOD = '' then 'unknown'
            else 'other'
        end as PAYMENT_METHOD,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as CREATED_AT,
        to_timestamp(UPDATED_AT) as UPDATED_AT,
        current_timestamp() as INGESTION_TIMESTAMP,
        -- Add data quality flags
        case 
            when CUSTOMER_ID like 'INVALID%' then true
            else false
        end as HAS_INVALID_CUSTOMER,
        case 
            when TOTAL_AMOUNT < 0 then true
            else false
        end as HAS_NEGATIVE_AMOUNT,
        case 
            when ORDER_STATUS not in ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned') then true
            else false
        end as HAS_INVALID_STATUS,
        case 
            when ORDER_DATE > current_date() then true
            else false
        end as HAS_FUTURE_DATE,
        case 
            when CURRENCY not in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then true
            else false
        end as HAS_INVALID_CURRENCY
    from source_data
),

-- Add order analysis fields
orders_with_analysis as (
    select 
        *,
        -- Order status category
        case 
            when ORDER_STATUS in ('delivered') then 'COMPLETED'
            when ORDER_STATUS in ('shipped', 'processing') then 'IN_PROGRESS'
            when ORDER_STATUS in ('pending') then 'PENDING'
            when ORDER_STATUS in ('cancelled', 'returned') then 'CANCELLED'
            else 'UNKNOWN'
        end as STATUS_CATEGORY,
        
        -- Order value tier
        case 
            when TOTAL_AMOUNT < 50 then 'SMALL'
            when TOTAL_AMOUNT < 200 then 'MEDIUM'
            when TOTAL_AMOUNT < 500 then 'LARGE'
            else 'XLARGE'
        end as ORDER_VALUE_TIER,
        
        -- Payment method category
        case 
            when PAYMENT_METHOD in ('credit_card', 'debit_card') then 'CARD'
            when PAYMENT_METHOD in ('paypal', 'apple_pay', 'google_pay') then 'DIGITAL_WALLET'
            when PAYMENT_METHOD = 'bank_transfer' then 'BANK_TRANSFER'
            else 'OTHER'
        end as PAYMENT_CATEGORY,
        
        -- Data quality score (0-100)
        case 
            when HAS_INVALID_CUSTOMER and HAS_NEGATIVE_AMOUNT and HAS_INVALID_STATUS then 0
            when HAS_INVALID_CUSTOMER and HAS_NEGATIVE_AMOUNT then 25
            when HAS_INVALID_CUSTOMER or HAS_NEGATIVE_AMOUNT then 50
            when HAS_INVALID_STATUS or HAS_FUTURE_DATE or HAS_INVALID_CURRENCY then 75
            else 100
        end as DATA_QUALITY_SCORE
    from cleaned_orders
)

select 
    ORDER_ID,
    CUSTOMER_ID,
    ORDER_DATE,
    ORDER_STATUS,
    TOTAL_AMOUNT,
    CURRENCY,
    SHIPPING_ADDRESS,
    PAYMENT_METHOD,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    HAS_INVALID_CUSTOMER,
    HAS_NEGATIVE_AMOUNT,
    HAS_INVALID_STATUS,
    HAS_FUTURE_DATE,
    HAS_INVALID_CURRENCY,
    STATUS_CATEGORY,
    ORDER_VALUE_TIER,
    PAYMENT_CATEGORY,
    DATA_QUALITY_SCORE,
    -- Add derived fields
    year(ORDER_DATE) as ORDER_YEAR,
    month(ORDER_DATE) as ORDER_MONTH,
    dayofweek(ORDER_DATE) as ORDER_DAY_OF_WEEK,
    quarter(ORDER_DATE) as ORDER_QUARTER,
    
    -- Order processing time (if completed)
    case 
        when ORDER_STATUS = 'delivered' and CREATED_AT is not null then
            datediff('day', CREATED_AT, UPDATED_AT)
        else null
    end as PROCESSING_DAYS
from orders_with_analysis
