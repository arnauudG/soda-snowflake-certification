# Comment Style Guide

This document defines the standardized comment style for all code files in this project.

## Python Files

### Module Docstrings
```python
#!/usr/bin/env python3
"""
Module Name - Brief Description

Detailed description of what this module does, its purpose, and key features.
Optional: Usage examples or important notes.
"""
```

### Function/Class Docstrings
```python
def function_name(param1: str, param2: int) -> bool:
    """
    Brief one-line description of the function.
    
    More detailed description if needed. Explain what the function does,
    any important behavior, or context.
    
    Args:
        param1: Description of param1
        param2: Description of param2
    
    Returns:
        Description of return value
    
    Raises:
        ValueError: When this error occurs
        TypeError: When this error occurs
    """
```

### Inline Comments
- Always use `#` followed by a space: `# Comment text`
- Capitalize first word unless it's a variable name or code reference
- Keep comments concise but descriptive
- Place comments above the code they describe, or inline for short explanations

```python
# Good examples:
# Process the data transformation
result = transform(data)

# Bad examples:
#process the data  # Missing space
# Process the data transformation  # Too verbose for simple operations
```

### Section Separators
Use consistent section separators for major code blocks:

```python
# =============================================================================
# SECTION NAME
# =============================================================================
```

## SQL Files

### Header Comments
```sql
-- Model/Table Name - Brief Description
-- 
-- Detailed description of what this model/table does.
-- Optional: Additional context, usage notes, or important information.
```

### Inline Comments
- Use `--` for SQL comments
- Place comments above the code they describe
- Capitalize first word unless it's a variable name or code reference

```sql
-- Good examples:
-- Calculate customer lifetime value
SELECT 
    customer_id,
    -- Sum of all order amounts
    SUM(order_amount) as total_spent
FROM orders

-- Bad examples:
--calculate customer lifetime value  # Missing space
--Calculate customer lifetime value  # Too verbose for simple operations
```

## General Guidelines

1. **Be Descriptive**: Comments should explain "why" not "what" (code should be self-explanatory)
2. **Keep Updated**: Update comments when code changes
3. **Avoid Redundancy**: Don't comment obvious code
4. **Use Consistent Formatting**: Follow the patterns defined above
5. **Capitalize Properly**: First word capitalized unless it's a code reference
6. **Spacing**: Always include space after comment markers (`#` or `--`)

## Examples

### Python Example
```python
#!/usr/bin/env python3
"""
Data Processing Module

This module handles data transformation and validation operations.
"""

# =============================================================================
# DATA TRANSFORMATION FUNCTIONS
# =============================================================================

def transform_customer_data(data: dict) -> dict:
    """
    Transform customer data to standardized format.
    
    Args:
        data: Raw customer data dictionary
    
    Returns:
        Transformed customer data dictionary
    
    Raises:
        ValueError: If required fields are missing
    """
    # Validate input data
    if not data.get('customer_id'):
        raise ValueError("customer_id is required")
    
    # Transform to uppercase
    return {
        'customer_id': data['customer_id'],
        'name': data['name'].upper()
    }
```

### SQL Example
```sql
-- Customer Dimension Table
-- 
-- Business-ready customer data with enriched attributes and segmentation.
-- This table is used for reporting and analytics.

{{ config(
    materialized='table',
    transient=false
) }}

-- Base customer data
with customers as (
    select * from {{ ref('stg_customers') }}
),

-- Add customer metrics
customer_metrics as (
    select 
        customer_id,
        -- Calculate total spent
        sum(order_amount) as total_spent
    from {{ ref('orders') }}
    group by customer_id
)

select * from customers
```

