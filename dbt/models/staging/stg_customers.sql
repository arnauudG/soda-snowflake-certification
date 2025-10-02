-- Staging model for customers (Silver layer)
-- Cleans and standardizes customer data from raw layer
-- Optimized for large dataset (10,000+ customers)

with source_data as (
    select * from {{ source('raw', 'CUSTOMERS') }}
),

cleaned_customers as (
    select
        CUSTOMER_ID,
        -- Clean and standardize names
        trim(upper(FIRST_NAME)) as first_name,
        trim(upper(LAST_NAME)) as last_name,
        -- Clean email (remove duplicates and invalid formats)
        case
            when EMAIL is null or EMAIL = '' then null
            when EMAIL like '%@%' and EMAIL not like '%@%@%' then lower(trim(EMAIL))
            else null
        end as email,
        -- Clean phone numbers
        case
            when PHONE is null or PHONE = '' then null
            when PHONE REGEXP '^[0-9\\-\\+\\(\\)\\s]+$' then PHONE
            else null
        end as phone,
        -- Clean address fields
        trim(ADDRESS) as address,
        trim(upper(CITY)) as city,
        trim(upper(STATE)) as state,
        trim(ZIP_CODE) as zip_code,
        trim(upper(COUNTRY)) as country,
        -- Standardize timestamps (convert from Unix timestamps to proper timestamps)
        to_timestamp(CREATED_AT) as created_at,
        to_timestamp(UPDATED_AT) as updated_at,
        current_timestamp() as ingestion_timestamp,
        -- Add data quality flags
        case
            when EMAIL is null or EMAIL = '' then true
            else false
        end as has_missing_email,
        case
            when PHONE is null or PHONE = '' then true
            else false
        end as has_missing_phone,
        case
            when FIRST_NAME is null or FIRST_NAME = '' then true
            else false
        end as has_missing_name
    from source_data
),

-- Remove duplicates based on email (keeping the latest record)
-- Optimized for large dataset with better performance
deduplicated_customers as (
    select 
        CUSTOMER_ID, first_name, last_name, email, phone, address, city, state,
        zip_code, country, created_at, updated_at, ingestion_timestamp,
        has_missing_email, has_missing_phone, has_missing_name
    from (
        select *,
            row_number() over (
                partition by email
                order by created_at desc, ingestion_timestamp desc
            ) as rn
        from cleaned_customers
        where email is not null
    )
    where rn = 1
    
    union all
    
    -- Keep all records with null emails (they can't be duplicates)
    select
        CUSTOMER_ID, first_name, last_name, email, phone, address, city, state,
        zip_code, country, created_at, updated_at, ingestion_timestamp,
        has_missing_email, has_missing_phone, has_missing_name
    from cleaned_customers
    where EMAIL is null
)

select 
    CUSTOMER_ID,
    first_name as FIRST_NAME,
    last_name as LAST_NAME,
    email as EMAIL,
    phone as PHONE,
    address as ADDRESS,
    city as CITY,
    state as STATE,
    zip_code as ZIP_CODE,
    country as COUNTRY,
    created_at as CREATED_AT,
    updated_at as UPDATED_AT,
    ingestion_timestamp as INGESTION_TIMESTAMP,
    has_missing_email as HAS_MISSING_EMAIL,
    has_missing_phone as HAS_MISSING_PHONE,
    has_missing_name as HAS_MISSING_NAME,
    -- Add derived fields
    concat(first_name, ' ', last_name) as FULL_NAME,
    case
        when country = 'USA' or country = 'UNITED STATES' then 'US'
        when country = 'CANADA' then 'CA'
        when country = 'UNITED KINGDOM' then 'UK'
        else upper(country)
    end as COUNTRY_CODE,
    -- Data quality score (0-100)
    case
        when has_missing_email and has_missing_phone and has_missing_name then 0
        when has_missing_email and has_missing_phone then 25
        when has_missing_email or has_missing_phone then 50
        when has_missing_name then 75
        else 100
    end as DATA_QUALITY_SCORE
from deduplicated_customers
