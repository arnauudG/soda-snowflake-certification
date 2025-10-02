-- Staging model for products (Silver layer)
-- Cleans and standardizes product data from raw layer
-- Optimized for large dataset (1,000+ products)

with source_data as (
    select * from {{ source('raw', 'PRODUCTS') }}
),

cleaned_products as (
    select
        PRODUCT_ID,
        -- Clean product name
        trim(PRODUCT_NAME) as product_name,
        -- Standardize category and subcategory
        trim(upper(CATEGORY)) as category,
        trim(upper(SUBCATEGORY)) as subcategory,
        -- Clean price (ensure positive values)
        case 
            when PRICE < 0 then null
            else PRICE
        end as price,
        -- Standardize currency
        case 
            when CURRENCY in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then CURRENCY
            else 'USD'
        end as currency,
        -- Clean description
        trim(DESCRIPTION) as description,
        -- Clean brand
        trim(upper(BRAND)) as brand,
        -- Clean SKU
        case 
            when SKU is null or SKU = '' then concat('SKU-', PRODUCT_ID)
            when SKU like 'INVALID%' then concat('SKU-', PRODUCT_ID)
            else trim(upper(SKU))
        end as sku,
        -- Clean weight (ensure positive values)
        case 
            when WEIGHT < 0 then null
            else WEIGHT
        end as weight,
        -- Clean dimensions
        trim(DIMENSIONS) as dimensions,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as created_at,
        to_timestamp(UPDATED_AT) as updated_at,
        current_timestamp() as ingestion_timestamp,
        -- Add data quality flags
        case 
            when PRICE < 0 then true
            else false
        end as has_negative_price,
        case 
            when PRODUCT_NAME is null or PRODUCT_NAME = '' then true
            else false
        end as has_missing_name,
        case 
            when WEIGHT < 0 then true
            else false
        end as has_negative_weight,
        case 
            when to_timestamp(CREATED_AT) > current_timestamp() then true
            else false
        end as has_future_date
    from source_data
),

-- Add product hierarchy
products_with_hierarchy as (
    select 
        *,
        -- Create product hierarchy levels
        case 
            when category in ('ELECTRONICS', 'CLOTHING', 'HOME & GARDEN') then 'HIGH_VOLUME'
            when category in ('SPORTS & OUTDOORS', 'BEAUTY & HEALTH') then 'MEDIUM_VOLUME'
            else 'LOW_VOLUME'
        end as volume_category,
        
        -- Price tier
        case 
            when price < 25 then 'BUDGET'
            when price < 100 then 'MID_RANGE'
            when price < 500 then 'PREMIUM'
            else 'LUXURY'
        end as price_tier,
        
        -- Data quality score (0-100)
        case 
            when has_negative_price and has_missing_name and has_negative_weight then 0
            when has_negative_price and has_missing_name then 25
            when has_negative_price or has_missing_name then 50
            when has_negative_weight or has_future_date then 75
            else 100
        end as data_quality_score
    from cleaned_products
)

select 
    product_id as PRODUCT_ID,
    product_name as PRODUCT_NAME,
    category as CATEGORY,
    subcategory as SUBCATEGORY,
    price as PRICE,
    currency as CURRENCY,
    description as DESCRIPTION,
    brand as BRAND,
    sku as SKU,
    weight as WEIGHT,
    dimensions as DIMENSIONS,
    created_at as CREATED_AT,
    updated_at as UPDATED_AT,
    ingestion_timestamp as INGESTION_TIMESTAMP,
    has_negative_price as HAS_NEGATIVE_PRICE,
    has_missing_name as HAS_MISSING_NAME,
    has_negative_weight as HAS_NEGATIVE_WEIGHT,
    has_future_date as HAS_FUTURE_DATE,
    volume_category as VOLUME_CATEGORY,
    price_tier as PRICE_TIER,
    data_quality_score as DATA_QUALITY_SCORE,
    -- Add derived fields
    case 
        when weight is not null and weight > 0 then 
            round(price / weight, 2)
        else null
    end as PRICE_PER_KG,
    
    -- Product age in days
    datediff('day', created_at, current_date()) as PRODUCT_AGE_DAYS
from products_with_hierarchy
