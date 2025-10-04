-- Product dimension table for mart layer
-- This model creates a clean, high-quality product dimension

{{ config(
    materialized='table',
    schema='mart'
) }}

SELECT 
    product_id,
    product_name,
    category,
    subcategory,
    price,
    currency,
    brand,
    sku,
    weight,
    dimensions,
    created_at,
    updated_at
FROM {{ ref('stg_products') }}
WHERE 
    -- Data quality filters for mart layer
    product_id IS NOT NULL
    AND product_name IS NOT NULL
    AND price IS NOT NULL
    AND price >= 0  -- Remove negative prices
    AND category IS NOT NULL
    AND brand IS NOT NULL
    AND sku IS NOT NULL
