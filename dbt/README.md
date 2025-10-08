# dbt Project - Soda Certification

This directory contains the dbt project configuration for the Soda Certification data pipeline, featuring clean schema management and lineage support.

## 🏗️ Project Structure

```
dbt/
├── models/
│   ├── raw/                    # Raw data sources
│   │   └── sources.yml         # Source table definitions
│   ├── staging/                # Staging transformations
│   │   ├── stg_customers.sql   # Customer staging model
│   │   ├── stg_orders.sql      # Order staging model
│   │   ├── stg_order_items.sql # Order items staging model
│   │   └── stg_products.sql    # Product staging model
│   └── mart/                   # Business-ready models
│       ├── dim_customers.sql   # Customer dimension
│       ├── dim_products.sql    # Product dimension
│       └── fact_orders.sql     # Order fact table
├── macros/
│   └── get_custom_schema.sql   # Custom schema macro
├── tests/
│   └── test_data_quality.sql   # Data quality tests
├── dbt_project.yml             # Project configuration
├── profiles.yml                # Snowflake connection profiles
└── README.md                   # This file
```

## 🎯 Schema Configuration

### **Clean Schema Management**
The project uses a custom schema macro to prevent schema concatenation issues:

- **Staging models**: Created in `STAGING` schema
- **Mart models**: Created in `MART` schema
- **No schema duplication**: Prevents `STAGING_STAGING` or `MART_MART` issues

### **Custom Schema Macro**
The `macros/get_custom_schema.sql` macro overrides dbt's default schema behavior:
- Uses project-level schema when specified (`STAGING`, `MART`)
- Falls back to profile schema (`PUBLIC`) only when no custom schema is set
- Prevents unwanted schema concatenation

## 📊 Data Models

### **Staging Layer (Silver)**
- **`stg_customers`**: Cleaned customer data with quality flags
- **`stg_orders`**: Validated order transactions with business logic
- **`stg_order_items`**: Processed order line items with calculations
- **`stg_products`**: Standardized product information with hierarchy

### **Mart Layer (Gold)**
- **`dim_customers`**: Customer dimension with segmentation and RFM analysis
- **`dim_products`**: Product dimension with categorization
- **`fact_orders`**: Order fact table with business metrics and analysis

## 🔧 Configuration

### **Project Configuration (`dbt_project.yml`)**
```yaml
models:
  soda_certification:
    staging:
      +materialized: table
      +schema: "STAGING"
      +tags: ["staging", "silver"]
      +meta:
        owner: "data-team"
        layer: "staging"
    mart:
      +materialized: table
      +schema: "MART"
      +tags: ["mart", "gold"]
      +meta:
        owner: "data-team"
        layer: "mart"
```

### **Profile Configuration (`profiles.yml`)**
```yaml
soda_certification:
  target: dev
  outputs:
    dev:
      type: snowflake
      database: "SODA_CERTIFICATION"
      warehouse: "COMPUTE_WH"
      schema: "PUBLIC"
      quote_identifiers: true
```

## 🚀 Usage

### **Run Staging Models**
```bash
dbt run --select staging --target dev --profiles-dir .
```

### **Run Mart Models**
```bash
dbt run --select mart --target dev --profiles-dir .
```

### **Run All Models**
```bash
dbt run --target dev --profiles-dir .
```

### **Run Tests**
```bash
dbt test --target dev --profiles-dir .
```

### **Generate Documentation**
```bash
dbt docs generate --target dev --profiles-dir .
dbt docs serve
```

## 📈 Data Quality Features

### **Staging Models**
- **Data Cleaning**: Standardized formats, trimmed whitespace
- **Quality Flags**: Missing data indicators, validation flags
- **Deduplication**: Removes duplicates based on business rules
- **Data Enrichment**: Adds derived fields and calculations

### **Mart Models**
- **Business Logic**: Customer segmentation, RFM analysis
- **Data Aggregation**: Order metrics, customer lifetime value
- **Quality Scoring**: Data quality assessment and scoring
- **Business Metrics**: Key performance indicators and KPIs

## 🔍 Testing

### **Data Quality Tests**
- **Uniqueness**: Primary key constraints
- **Referential Integrity**: Foreign key relationships
- **Completeness**: Required field validation
- **Business Rules**: Domain-specific validations

### **Test Execution**
```bash
# Run all tests
dbt test --target dev --profiles-dir .

# Run specific test
dbt test --select test_data_quality --target dev --profiles-dir .
```

## 📚 Best Practices

### **Model Development**
1. **Naming Convention**: Use descriptive, consistent names
2. **Documentation**: Document all models and columns
3. **Testing**: Include appropriate tests for each model
4. **Performance**: Use appropriate materialization strategies

### **Schema Management**
1. **Layer Separation**: Keep staging and mart models separate
2. **Schema Configuration**: Use project-level schema settings
3. **Custom Macros**: Leverage custom macros for complex logic
4. **Lineage**: Maintain clear data lineage documentation

## 🛠️ Troubleshooting

### **Common Issues**

#### **Schema Concatenation**
- **Issue**: Models created in `STAGING_STAGING` or `MART_MART`
- **Solution**: Ensure custom schema macro is in place and project config is correct

#### **Connection Issues**
- **Issue**: Cannot connect to Snowflake
- **Solution**: Verify environment variables and profile configuration

#### **Model Dependencies**
- **Issue**: Models can't find referenced tables
- **Solution**: Ensure staging models run before mart models

### **Debug Commands**
```bash
# Parse project
dbt parse --target dev --profiles-dir .

# Debug connection
dbt debug --target dev --profiles-dir .

# Show compiled SQL
dbt compile --select stg_customers --target dev --profiles-dir .
```

## 📊 Lineage Support

### **Metadata Configuration**
The project includes lineage metadata configuration:
- **Model Metadata**: Owner, layer, and business context
- **Column Documentation**: Detailed column descriptions
- **Data Lineage**: Visual representation of data flow

### **Lineage Visualization**
- **dbt Docs**: Built-in lineage visualization
- **Custom Schema Macro**: Ensures clean schema names in lineage
- **Metadata Tables**: Creates lineage metadata in Snowflake

## 🎯 Success Metrics

✅ **Clean Schema Management**: No schema concatenation issues  
✅ **Layer Separation**: Clear staging and mart model separation  
✅ **Data Quality**: Comprehensive data cleaning and validation  
✅ **Business Logic**: Rich business metrics and segmentation  
✅ **Testing**: Comprehensive data quality tests  
✅ **Documentation**: Complete model and column documentation  
✅ **Lineage Support**: Visual data lineage and metadata tracking  
✅ **Performance**: Optimized materialization strategies  

---

**Last Updated**: December 2024  
**Version**: 1.0.0  
**dbt Version**: 1.10.11
