-- Performance Optimization Indexes
-- Business Analytics Database

USE business_analytics;

-- =====================================================
-- COMPOSITE INDEXES FOR COMMON QUERIES
-- =====================================================

-- Sales fact table composite indexes
CREATE INDEX idx_sales_date_customer ON fact_sales(date_id, customer_id);
CREATE INDEX idx_sales_date_product ON fact_sales(date_id, product_id);
CREATE INDEX idx_sales_date_status ON fact_sales(date_id, order_status);
CREATE INDEX idx_sales_customer_status ON fact_sales(customer_id, order_status);
CREATE INDEX idx_sales_product_status ON fact_sales(product_id, order_status);

-- Revenue fact table composite indexes
CREATE INDEX idx_revenue_date_customer ON fact_revenue(date_id, customer_id);
CREATE INDEX idx_revenue_date_product ON fact_revenue(date_id, product_id);

-- =====================================================
-- COVERING INDEXES FOR ANALYTICS QUERIES
-- =====================================================

-- Index for revenue calculation queries
CREATE INDEX idx_sales_revenue_calc ON fact_sales(
    date_id, 
    order_status, 
    total_amount, 
    profit_amount
);

-- Index for customer analytics
CREATE INDEX idx_customer_analytics ON fact_sales(
    customer_id, 
    order_status, 
    date_id, 
    total_amount
);

-- Index for product analytics
CREATE INDEX idx_product_analytics ON fact_sales(
    product_id, 
    order_status, 
    quantity, 
    total_amount, 
    profit_amount
);

-- =====================================================
-- ANALYZE TABLES FOR OPTIMIZER
-- =====================================================

ANALYZE TABLE dim_date;
ANALYZE TABLE dim_customers;
ANALYZE TABLE dim_products;
ANALYZE TABLE dim_sales_reps;
ANALYZE TABLE fact_sales;
ANALYZE TABLE fact_revenue;

-- =====================================================
-- INDEX MAINTENANCE COMMANDS (Run periodically)
-- =====================================================

-- Optimize tables to reclaim space and update statistics
-- OPTIMIZE TABLE fact_sales;
-- OPTIMIZE TABLE fact_revenue;
-- OPTIMIZE TABLE dim_customers;
-- OPTIMIZE TABLE dim_products;