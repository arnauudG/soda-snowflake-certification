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
        end as order_id,
        -- Clean product_id
        case 
            when PRODUCT_ID like 'INVALID%' then null
            else PRODUCT_ID
        end as product_id,
        -- Clean quantity (ensure positive values)
        case 
            when QUANTITY < 0 then null
            when QUANTITY = 0 then null
            else QUANTITY
        end as quantity,
        -- Clean unit price (ensure positive values)
        case 
            when UNIT_PRICE < 0 then null
            else UNIT_PRICE
        end as unit_price,
        -- Clean total price (ensure positive values)
        case 
            when TOTAL_PRICE < 0 then null
            else TOTAL_PRICE
        end as total_price,
        -- Clean discount percent (ensure valid range)
        case 
            when DISCOUNT_PERCENT < 0 then 0
            when DISCOUNT_PERCENT > 100 then 100
            else DISCOUNT_PERCENT
        end as discount_percent,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as created_at,
        to_timestamp(UPDATED_AT) as updated_at,
        current_timestamp() as ingestion_timestamp,
        -- Add data quality flags
        case 
            when ORDER_ID like 'INVALID%' then true
            else false
        end as has_invalid_order,
        case 
            when PRODUCT_ID like 'INVALID%' then true
            else false
        end as has_invalid_product,
        case 
            when QUANTITY < 0 then true
            else false
        end as has_negative_quantity,
        case 
            when UNIT_PRICE < 0 then true
            else false
        end as has_negative_price,
        case 
            when TOTAL_PRICE < 0 then true
            else false
        end as has_negative_total
    from source_data
),

-- Add calculated fields and validation
order_items_with_calculations as (
    select 
        *,
        -- Recalculate total price if it doesn't match quantity * unit_price
        case 
            when quantity is not null and unit_price is not null then
                round(quantity * unit_price * (1 - discount_percent / 100), 2)
            else total_price
        end as calculated_total_price,
        
        -- Discount amount
        case 
            when quantity is not null and unit_price is not null then
                round(quantity * unit_price * (discount_percent / 100), 2)
            else 0
        end as discount_amount,
        
        -- Data quality score (0-100)
        case 
            when has_invalid_order and has_invalid_product and has_negative_quantity then 0
            when has_invalid_order and has_invalid_product then 25
            when has_invalid_order or has_invalid_product then 50
            when has_negative_quantity or has_negative_price or has_negative_total then 75
            else 100
        end as data_quality_score
    from cleaned_order_items
)

select 
    order_item_id as ORDER_ITEM_ID,
    order_id as ORDER_ID,
    product_id as PRODUCT_ID,
    quantity as QUANTITY,
    unit_price as UNIT_PRICE,
    total_price as TOTAL_PRICE,
    calculated_total_price as CALCULATED_TOTAL_PRICE,
    discount_percent as DISCOUNT_PERCENT,
    discount_amount as DISCOUNT_AMOUNT,
    created_at as CREATED_AT,
    updated_at as UPDATED_AT,
    ingestion_timestamp as INGESTION_TIMESTAMP,
    has_invalid_order as HAS_INVALID_ORDER,
    has_invalid_product as HAS_INVALID_PRODUCT,
    has_negative_quantity as HAS_NEGATIVE_QUANTITY,
    has_negative_price as HAS_NEGATIVE_PRICE,
    has_negative_total as HAS_NEGATIVE_TOTAL,
    data_quality_score as DATA_QUALITY_SCORE,
    -- Add derived fields
    case 
        when quantity is not null and unit_price is not null then
            round(unit_price / quantity, 2)
        else null
    end as PRICE_PER_UNIT,
    
    -- Item value tier
    case 
        when calculated_total_price < 25 then 'SMALL'
        when calculated_total_price < 100 then 'MEDIUM'
        when calculated_total_price < 500 then 'LARGE'
        else 'XLARGE'
    end as ITEM_VALUE_TIER,
    
    -- Discount tier
    case 
        when discount_percent = 0 then 'NO_DISCOUNT'
        when discount_percent < 10 then 'LOW_DISCOUNT'
        when discount_percent < 25 then 'MEDIUM_DISCOUNT'
        else 'HIGH_DISCOUNT'
    end as DISCOUNT_TIER
from order_items_with_calculations
