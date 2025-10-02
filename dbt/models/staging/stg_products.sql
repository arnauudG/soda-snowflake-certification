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
        trim(PRODUCT_NAME) as PRODUCT_NAME,
        -- Standardize category and subcategory
        trim(upper(CATEGORY)) as CATEGORY,
        trim(upper(SUBCATEGORY)) as SUBCATEGORY,
        -- Clean price (ensure positive values)
        case 
            when PRICE < 0 then null
            else PRICE
        end as PRICE,
        -- Standardize currency
        case 
            when CURRENCY in ('USD', 'EUR', 'GBP', 'CAD', 'AUD') then CURRENCY
            else 'USD'
        end as CURRENCY,
        -- Clean description
        trim(DESCRIPTION) as DESCRIPTION,
        -- Clean brand
        trim(upper(BRAND)) as BRAND,
        -- Clean SKU
        case 
            when SKU is null or SKU = '' then concat('SKU-', PRODUCT_ID)
            when SKU like 'INVALID%' then concat('SKU-', PRODUCT_ID)
            else trim(upper(SKU))
        end as SKU,
        -- Clean weight (ensure positive values)
        case 
            when WEIGHT < 0 then null
            else WEIGHT
        end as WEIGHT,
        -- Clean dimensions
        trim(DIMENSIONS) as DIMENSIONS,
        -- Standardize timestamps
        to_timestamp(CREATED_AT) as CREATED_AT,
        to_timestamp(UPDATED_AT) as UPDATED_AT,
        current_timestamp() as INGESTION_TIMESTAMP,
        -- Add data quality flags
        case 
            when PRICE < 0 then true
            else false
        end as HAS_NEGATIVE_PRICE,
        case 
            when PRODUCT_NAME is null or PRODUCT_NAME = '' then true
            else false
        end as HAS_MISSING_NAME,
        case 
            when WEIGHT < 0 then true
            else false
        end as HAS_NEGATIVE_WEIGHT,
        case 
            when to_timestamp(CREATED_AT) > current_timestamp() then true
            else false
        end as HAS_FUTURE_DATE
    from source_data
),

-- Add product hierarchy
products_with_hierarchy as (
    select 
        *,
        -- Create product hierarchy levels
        case 
            when CATEGORY in ('ELECTRONICS', 'CLOTHING', 'HOME & GARDEN') then 'HIGH_VOLUME'
            when CATEGORY in ('SPORTS & OUTDOORS', 'BEAUTY & HEALTH') then 'MEDIUM_VOLUME'
            else 'LOW_VOLUME'
        end as VOLUME_CATEGORY,
        
        -- Price tier
        case 
            when PRICE < 25 then 'BUDGET'
            when PRICE < 100 then 'MID_RANGE'
            when PRICE < 500 then 'PREMIUM'
            else 'LUXURY'
        end as PRICE_TIER,
        
        -- Data quality score (0-100)
        case 
            when HAS_NEGATIVE_PRICE and HAS_MISSING_NAME and HAS_NEGATIVE_WEIGHT then 0
            when HAS_NEGATIVE_PRICE and HAS_MISSING_NAME then 25
            when HAS_NEGATIVE_PRICE or HAS_MISSING_NAME then 50
            when HAS_NEGATIVE_WEIGHT or HAS_FUTURE_DATE then 75
            else 100
        end as DATA_QUALITY_SCORE
    from cleaned_products
)

select 
    PRODUCT_ID,
    PRODUCT_NAME,
    CATEGORY,
    SUBCATEGORY,
    PRICE,
    CURRENCY,
    DESCRIPTION,
    BRAND,
    SKU,
    WEIGHT,
    DIMENSIONS,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    HAS_NEGATIVE_PRICE,
    HAS_MISSING_NAME,
    HAS_NEGATIVE_WEIGHT,
    HAS_FUTURE_DATE,
    VOLUME_CATEGORY,
    PRICE_TIER,
    DATA_QUALITY_SCORE,
    -- Add derived fields
    case 
        when WEIGHT is not null and WEIGHT > 0 then 
            round(PRICE / WEIGHT, 2)
        else null
    end as PRICE_PER_KG,
    
    -- Product age in days
    datediff('day', CREATED_AT, current_date()) as PRODUCT_AGE_DAYS
from products_with_hierarchy
