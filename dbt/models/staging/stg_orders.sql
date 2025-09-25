-- Staging model for orders (Silver layer)
-- Cleans and standardizes order data from raw layer
-- Optimized for large dataset (20,000+ orders)

with source_data as (
    select * from SODA_CERTIFICATION.RAW.ORDERS
),

cleaned_orders as (
    select
        ORDER_ID,
        -- Clean customer_id
        case 
            when CUSTOMER_ID like 'INVALID%' then null
            else CUSTOMER_ID
        end as customer_id,
        -- Clean order date
        case 
            when ORDER_DATE > current_date() then null
            else ORDER_DATE
        end as order_date,
        -- Clean order status
        case 
            when ORDER_STATUS in ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned') 
            then ORDER_STATUS
            else 'unknown'
        end as order_status,
        -- Clean total amount (ensure positive values)
        case 
            when TOTAL_AMOUNT < 0 then null
            when TOTAL_AMOUNT = 0 then null
            else TOTAL_AMOUNT
        end as total_amount,
        -- Standardize currency
        case 
            when CURRENCY in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then CURRENCY
            else 'USD'
        end as currency,
        -- Clean shipping address
        trim(SHIPPING_ADDRESS) as shipping_address,
        -- Clean payment method
        case 
            when PAYMENT_METHOD in ('credit_card', 'debit_card', 'paypal', 'apple_pay', 'google_pay', 'bank_transfer')
            then PAYMENT_METHOD
            when PAYMENT_METHOD is null or PAYMENT_METHOD = '' then 'unknown'
            else 'other'
        end as payment_method,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as created_at,
        to_timestamp(UPDATED_AT) as updated_at,
        current_timestamp() as ingestion_timestamp,
        -- Add data quality flags
        case 
            when CUSTOMER_ID like 'INVALID%' then true
            else false
        end as has_invalid_customer,
        case 
            when TOTAL_AMOUNT < 0 then true
            else false
        end as has_negative_amount,
        case 
            when ORDER_STATUS not in ('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'returned') then true
            else false
        end as has_invalid_status,
        case 
            when ORDER_DATE > current_date() then true
            else false
        end as has_future_date,
        case 
            when CURRENCY not in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then true
            else false
        end as has_invalid_currency
    from source_data
),

-- Add order analysis fields
orders_with_analysis as (
    select 
        *,
        -- Order status category
        case 
            when order_status in ('delivered') then 'COMPLETED'
            when order_status in ('shipped', 'processing') then 'IN_PROGRESS'
            when order_status in ('pending') then 'PENDING'
            when order_status in ('cancelled', 'returned') then 'CANCELLED'
            else 'UNKNOWN'
        end as status_category,
        
        -- Order value tier
        case 
            when total_amount < 50 then 'SMALL'
            when total_amount < 200 then 'MEDIUM'
            when total_amount < 500 then 'LARGE'
            else 'XLARGE'
        end as order_value_tier,
        
        -- Payment method category
        case 
            when payment_method in ('credit_card', 'debit_card') then 'CARD'
            when payment_method in ('paypal', 'apple_pay', 'google_pay') then 'DIGITAL_WALLET'
            when payment_method = 'bank_transfer' then 'BANK_TRANSFER'
            else 'OTHER'
        end as payment_category,
        
        -- Data quality score (0-100)
        case 
            when has_invalid_customer and has_negative_amount and has_invalid_status then 0
            when has_invalid_customer and has_negative_amount then 25
            when has_invalid_customer or has_negative_amount then 50
            when has_invalid_status or has_future_date or has_invalid_currency then 75
            else 100
        end as data_quality_score
    from cleaned_orders
)

select 
    order_id,
    customer_id,
    order_date,
    order_status,
    total_amount,
    currency,
    shipping_address,
    payment_method,
    created_at,
    updated_at,
    ingestion_timestamp,
    has_invalid_customer,
    has_negative_amount,
    has_invalid_status,
    has_future_date,
    has_invalid_currency,
    status_category,
    order_value_tier,
    payment_category,
    data_quality_score,
    -- Add derived fields
    year(order_date) as order_year,
    month(order_date) as order_month,
    dayofweek(order_date) as order_day_of_week,
    quarter(order_date) as order_quarter,
    
    -- Order processing time (if completed)
    case 
        when order_status = 'delivered' and created_at is not null then
            datediff('day', created_at, updated_at)
        else null
    end as processing_days
from orders_with_analysis
