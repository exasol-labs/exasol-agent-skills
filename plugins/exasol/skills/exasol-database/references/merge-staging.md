# MERGE Staging Patterns

## Basic Staging Workflow

```sql
-- 1. Create a staging table matching the source structure
CREATE TABLE staging.orders_stg (LIKE production.orders INCLUDING DEFAULTS);

-- 2. Import into staging (with error handling)
IMPORT INTO staging.orders_stg
FROM CSV AT s3_conn FILE 'daily/orders_*.csv'
COLUMN SEPARATOR = ','
SKIP = 1
REJECT LIMIT 100;

-- 3. Merge staging into production
MERGE INTO production.orders t
USING staging.orders_stg s ON (t.order_id = s.order_id)
WHEN MATCHED THEN UPDATE SET
    t.status = s.status,
    t.amount = s.amount,
    t.updated_at = CURRENT_TIMESTAMP
WHEN NOT MATCHED THEN INSERT VALUES (
    s.order_id, s.customer_id, s.status, s.amount, CURRENT_TIMESTAMP
);

-- 4. Clean up staging
TRUNCATE TABLE staging.orders_stg;
COMMIT;
```

## SCD Type 2 Pattern

```sql
-- Close existing active records that have changes
MERGE INTO dim_customer t
USING staging.customer_stg s ON (t.customer_id = s.customer_id AND t.is_current = TRUE)
WHEN MATCHED AND (t.name != s.name OR t.address != s.address) THEN
    UPDATE SET t.is_current = FALSE, t.valid_to = CURRENT_DATE;

-- Insert new/changed records
INSERT INTO dim_customer (customer_id, name, address, valid_from, valid_to, is_current)
SELECT s.customer_id, s.name, s.address, CURRENT_DATE, DATE '9999-12-31', TRUE
FROM staging.customer_stg s
WHERE NOT EXISTS (
    SELECT 1 FROM dim_customer t
    WHERE t.customer_id = s.customer_id AND t.is_current = TRUE
    AND t.name = s.name AND t.address = s.address
);
```

## REJECT LIMIT for IMPORT Error Handling

```sql
-- Allow up to 100 rejected rows before failing
IMPORT INTO my_table FROM CSV AT conn FILE 'data.csv'
REJECT LIMIT 100;

-- Check rejected rows
SELECT * FROM EXA_DBA_AUDIT_SESSIONS WHERE COMMAND_NAME = 'IMPORT';
```
