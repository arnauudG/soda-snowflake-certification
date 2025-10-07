-- Staging model for customers (Silver layer)
-- Cleans and standardizes customer data from raw layer
-- Optimized for large dataset (10,000+ customers)
-- 
-- This table contains cleaned customer data from the raw CUSTOMERS table
-- with data quality improvements and standardization

{{ config(
    materialized='table',
    transient=false
) }}

with source_data as (
    select * from {{ source('raw', 'CUSTOMERS') }}
),

cleaned_customers as (
    select
        CUSTOMER_ID,
        -- Clean and standardize names
        trim(upper(FIRST_NAME)) as FIRST_NAME,
        trim(upper(LAST_NAME)) as LAST_NAME,
        -- Clean email (remove duplicates and invalid formats)
        case
            when EMAIL is null or EMAIL = '' then null
            when EMAIL like '%@%' and EMAIL not like '%@%@%' then lower(trim(EMAIL))
            else null
        end as EMAIL,
        -- Clean phone numbers
        case
            when PHONE is null or PHONE = '' then null
            when PHONE REGEXP '^[0-9\\-\\+\\(\\)\\s]+$' then PHONE
            else null
        end as PHONE,
        -- Clean address fields
        trim(ADDRESS) as ADDRESS,
        trim(upper(CITY)) as CITY,
        trim(upper(STATE)) as STATE,
        trim(ZIP_CODE) as ZIP_CODE,
        trim(upper(COUNTRY)) as COUNTRY,
        -- Standardize timestamps (convert from Unix timestamps to proper timestamps)
        to_timestamp(CREATED_AT) as CREATED_AT,
        to_timestamp(UPDATED_AT) as UPDATED_AT,
        current_timestamp() as INGESTION_TIMESTAMP,
        -- Add data quality flags
        case
            when EMAIL is null or EMAIL = '' then true
            else false
        end as HAS_MISSING_EMAIL,
        case
            when PHONE is null or PHONE = '' then true
            else false
        end as HAS_MISSING_PHONE,
        case
            when FIRST_NAME is null or FIRST_NAME = '' then true
            else false
        end as HAS_MISSING_NAME
    from source_data
),

-- Remove duplicates based on email (keeping the latest record)
-- Optimized for large dataset with better performance
deduplicated_customers as (
    select 
        CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, CITY, STATE,
        ZIP_CODE, COUNTRY, CREATED_AT, UPDATED_AT, INGESTION_TIMESTAMP,
        HAS_MISSING_EMAIL, HAS_MISSING_PHONE, HAS_MISSING_NAME
    from (
        select *,
            row_number() over (
                partition by EMAIL
                order by CREATED_AT desc, INGESTION_TIMESTAMP desc
            ) as rn
        from cleaned_customers
        where EMAIL is not null
    )
    where rn = 1
    
    union all
    
    -- Keep all records with null emails (they can't be duplicates)
    select
        CUSTOMER_ID, FIRST_NAME, LAST_NAME, EMAIL, PHONE, ADDRESS, CITY, STATE,
        ZIP_CODE, COUNTRY, CREATED_AT, UPDATED_AT, INGESTION_TIMESTAMP,
        HAS_MISSING_EMAIL, HAS_MISSING_PHONE, HAS_MISSING_NAME
    from cleaned_customers
    where EMAIL is null
)

select 
    CUSTOMER_ID,
    FIRST_NAME,
    LAST_NAME,
    EMAIL,
    PHONE,
    ADDRESS,
    CITY,
    STATE,
    ZIP_CODE,
    COUNTRY,
    CREATED_AT,
    UPDATED_AT,
    INGESTION_TIMESTAMP,
    HAS_MISSING_EMAIL,
    HAS_MISSING_PHONE,
    HAS_MISSING_NAME,
    -- Add derived fields
    concat(FIRST_NAME, ' ', LAST_NAME) as FULL_NAME,
    case
        when COUNTRY = 'USA' or COUNTRY = 'UNITED STATES' then 'US'
        when COUNTRY = 'CANADA' then 'CA'
        when COUNTRY = 'UNITED KINGDOM' then 'UK'
        else upper(COUNTRY)
    end as COUNTRY_CODE,
    -- Data quality score (0-100)
    case
        when HAS_MISSING_EMAIL and HAS_MISSING_PHONE and HAS_MISSING_NAME then 0
        when HAS_MISSING_EMAIL and HAS_MISSING_PHONE then 25
        when HAS_MISSING_EMAIL or HAS_MISSING_PHONE then 50
        when HAS_MISSING_NAME then 75
        else 100
    end as DATA_QUALITY_SCORE
from deduplicated_customers
