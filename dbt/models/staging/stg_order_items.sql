-- Staging model for order items (Silver layer)
-- Cleans and standardizes order item data from raw layer
-- Optimized for large dataset (50,000+ order items)

with source_data as (
    select * from {{ source('raw', 'ORDER_ITEMS') }}
),

cleaned_order_items as (
    select
        ORDER_ITEM_ID,
        -- Clean order_id
        case 
            when ORDER_ID like 'INVALID%' then null
            else ORDER_ID
        end as ORDER_ID,
        -- Clean product_id
        case 
            when PRODUCT_ID like 'INVALID%' then null
            else PRODUCT_ID
        end as PRODUCT_ID,
        -- Clean quantity (ensure positive values)
        case 
            when QUANTITY < 0 then null
            when QUANTITY = 0 then null
            else QUANTITY
        end as QUANTITY,
        -- Clean unit price (ensure positive values)
        case 
            when UNIT_PRICE < 0 then null
            else UNIT_PRICE
        end as UNIT_PRICE,
        -- Clean total price (ensure positive values)
        case 
            when TOTAL_PRICE < 0 then null
            else TOTAL_PRICE
        end as TOTAL_PRICE,
        -- Clean discount percent (ensure valid range)
        case 
            when DISCOUNT_PERCENT < 0 then 0
            when DISCOUNT_PERCENT > 100 then 100
            else DISCOUNT_PERCENT
        end as DISCOUNT_PERCENT,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as CREATED_AT,
        to_timestamp(UPDATED_AT) as UPDATED_AT,
        current_timestamp() as INGESTION_TIMESTAMP,
        -- Add data quality flags
        case 
            when ORDER_ID like 'INVALID%' then true
            else false
        end as HAS_INVALID_ORDER,
        case 
            when PRODUCT_ID like 'INVALID%' then true
            else false
        end as HAS_INVALID_PRODUCT,
        case 
            when QUANTITY < 0 then true
            else false
        end as HAS_NEGATIVE_QUANTITY,
        case 
            when UNIT_PRICE < 0 then true
            else false
        end as HAS_NEGATIVE_PRICE,
        case 
            when TOTAL_PRICE < 0 then true
            else false
        end as HAS_NEGATIVE_TOTAL
    from source_data
),

-- Add calculated fields and validation
order_items_with_calculations as (
    select 
        *,
        -- Recalculate total price if it doesn't match quantity * unit_price
        case 
            when QUANTITY is not null and UNIT_PRICE is not null then
                round(QUANTITY * UNIT_PRICE * (1 - DISCOUNT_PERCENT / 100), 2)
            else TOTAL_PRICE
        end as CALCULATED_TOTAL_PRICE,
        
        -- Discount amount
        case 
            when QUANTITY is not null and UNIT_PRICE is not null then
                round(QUANTITY * UNIT_PRICE * (DISCOUNT_PERCENT / 100), 2)
            else 0
        end as DISCOUNT_AMOUNT,
        
        -- Data quality score (0-100)
        case 
            when HAS_INVALID_ORDER and HAS_INVALID_PRODUCT and HAS_NEGATIVE_QUANTITY then 0
            when HAS_INVALID_ORDER and HAS_INVALID_PRODUCT then 25
            when HAS_INVALID_ORDER or HAS_INVALID_PRODUCT then 50
            when HAS_NEGATIVE_QUANTITY or HAS_NEGATIVE_PRICE or HAS_NEGATIVE_TOTAL then 75
            else 100
        end as DATA_QUALITY_SCORE
    from cleaned_order_items
)

select 
    ORDER_ITEM_ID,
    ORDER_ID,
    PRODUCT_ID,
    QUANTITY,
    UNIT_PRICE,
    TOTAL_PRICE,
    CALCULATED_TOTAL_PRICE,
    DISCOUNT_PERCENT,
    DISCOUNT_AMOUNT,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    HAS_INVALID_ORDER,
    HAS_INVALID_PRODUCT,
    HAS_NEGATIVE_QUANTITY,
    HAS_NEGATIVE_PRICE,
    HAS_NEGATIVE_TOTAL,
    DATA_QUALITY_SCORE,
    -- Add derived fields
    case 
        when QUANTITY is not null and UNIT_PRICE is not null then
            round(UNIT_PRICE / QUANTITY, 2)
        else null
    end as PRICE_PER_UNIT,
    
    -- Item value tier
    case 
        when CALCULATED_TOTAL_PRICE < 25 then 'SMALL'
        when CALCULATED_TOTAL_PRICE < 100 then 'MEDIUM'
        when CALCULATED_TOTAL_PRICE < 500 then 'LARGE'
        else 'XLARGE'
    end as ITEM_VALUE_TIER,
    
    -- Discount tier
    case 
        when DISCOUNT_PERCENT = 0 then 'NO_DISCOUNT'
        when DISCOUNT_PERCENT < 10 then 'LOW_DISCOUNT'
        when DISCOUNT_PERCENT < 25 then 'MEDIUM_DISCOUNT'
        else 'HIGH_DISCOUNT'
    end as DISCOUNT_TIER
from order_items_with_calculations
