-- Analytics Views for Business Intelligence
USE business_analytics;

-- =====================================================
-- REVENUE ANALYTICS VIEWS
-- =====================================================

-- Monthly Revenue Summary
CREATE OR REPLACE VIEW vw_monthly_revenue AS
SELECT 
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.quantity) AS total_quantity,
    SUM(s.subtotal) AS gross_revenue,
    SUM(s.discount_amount) AS total_discount,
    SUM(s.total_amount) AS net_revenue,
    SUM(s.cost_amount) AS total_cost,
    SUM(s.profit_amount) AS total_profit,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.order_status = 'Completed'
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year DESC, d.month DESC;

-- Quarterly Revenue Summary
CREATE OR REPLACE VIEW vw_quarterly_revenue AS
SELECT 
    d.year,
    d.quarter,
    CONCAT('Q', d.quarter, ' ', d.year) AS quarter_label,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.quantity) AS total_quantity,
    SUM(s.total_amount) AS net_revenue,
    SUM(s.profit_amount) AS total_profit,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.order_status = 'Completed'
GROUP BY d.year, d.quarter
ORDER BY d.year DESC, d.quarter DESC;

-- =====================================================
-- CUSTOMER ANALYTICS VIEWS
-- =====================================================

-- Customer Performance Metrics
CREATE OR REPLACE VIEW vw_customer_metrics AS
SELECT 
    c.customer_id,
    c.customer_code,
    c.customer_name,
    c.customer_type,
    c.segment,
    c.country,
    c.status,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_items_purchased,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) AS total_profit,
    MAX(d.full_date) AS last_purchase_date,
    DATEDIFF(CURDATE(), MAX(d.full_date)) AS days_since_last_purchase
FROM dim_customers c
LEFT JOIN fact_sales s ON c.customer_id = s.customer_id AND s.order_status = 'Completed'
LEFT JOIN dim_date d ON s.date_id = d.date_id
GROUP BY c.customer_id, c.customer_code, c.customer_name, c.customer_type, 
         c.segment, c.country, c.status;

-- Customer Segmentation
CREATE OR REPLACE VIEW vw_customer_segmentation AS
SELECT 
    c.segment,
    c.customer_type,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_revenue_per_customer,
    SUM(s.profit_amount) AS total_profit
FROM dim_customers c
LEFT JOIN fact_sales s ON c.customer_id = s.customer_id AND s.order_status = 'Completed'
GROUP BY c.segment, c.customer_type
ORDER BY total_revenue DESC;

-- =====================================================
-- PRODUCT ANALYTICS VIEWS
-- =====================================================

-- Product Performance
CREATE OR REPLACE VIEW vw_product_performance AS
SELECT 
    p.product_id,
    p.product_code,
    p.product_name,
    p.category,
    p.subcategory,
    p.brand,
    p.unit_price,
    p.status,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_sale_value,
    SUM(s.profit_amount) AS total_profit,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM dim_products p
LEFT JOIN fact_sales s ON p.product_id = s.product_id AND s.order_status = 'Completed'
GROUP BY p.product_id, p.product_code, p.product_name, p.category, 
         p.subcategory, p.brand, p.unit_price, p.status
ORDER BY total_revenue DESC;

-- Category Performance
CREATE OR REPLACE VIEW vw_category_performance AS
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM dim_products p
LEFT JOIN fact_sales s ON p.product_id = s.product_id AND s.order_status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- =====================================================
-- SALES REPRESENTATIVE ANALYTICS
-- =====================================================

-- Sales Rep Performance
CREATE OR REPLACE VIEW vw_sales_rep_performance AS
SELECT 
    sr.sales_rep_id,
    sr.employee_code,
    sr.full_name,
    sr.region,
    sr.status,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) AS total_profit
FROM dim_sales_reps sr
LEFT JOIN fact_sales s ON sr.sales_rep_id = s.sales_rep_id AND s.order_status = 'Completed'
GROUP BY sr.sales_rep_id, sr.employee_code, sr.full_name, sr.region, sr.status
ORDER BY total_revenue DESC;

-- Regional Performance
CREATE OR REPLACE VIEW vw_regional_performance AS
SELECT 
    sr.region,
    COUNT(DISTINCT sr.sales_rep_id) AS sales_rep_count,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) AS total_profit
FROM dim_sales_reps sr
LEFT JOIN fact_sales s ON sr.sales_rep_id = s.sales_rep_id AND s.order_status = 'Completed'
GROUP BY sr.region
ORDER BY total_revenue DESC;

-- =====================================================
-- EXECUTIVE DASHBOARD VIEW
-- =====================================================

-- Key Performance Indicators (Current vs Previous Month)
CREATE OR REPLACE VIEW vw_kpi_summary AS
SELECT 
    'Current Month' AS period_type,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE d.year = YEAR(CURDATE()) 
  AND d.month = MONTH(CURDATE())
  AND s.order_status = 'Completed'

UNION ALL

SELECT 
    'Previous Month' AS period_type,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    COUNT(DISTINCT s.customer_id) AS unique_customers,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    AVG(s.total_amount) AS avg_order_value,
    SUM(s.profit_amount) / NULLIF(SUM(s.total_amount), 0) * 100 AS profit_margin_pct
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE d.year = YEAR(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
  AND d.month = MONTH(DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
  AND s.order_status = 'Completed';

-- =====================================================
-- TREND ANALYSIS VIEW
-- =====================================================

-- Daily Sales Trend (Last 90 Days)
CREATE OR REPLACE VIEW vw_daily_sales_trend AS
SELECT 
    d.full_date,
    d.day_name,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.quantity) AS total_quantity,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    AVG(s.total_amount) AS avg_order_value
FROM dim_date d
LEFT JOIN fact_sales s ON d.date_id = s.date_id AND s.order_status = 'Completed'
WHERE d.full_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY d.full_date, d.day_name
ORDER BY d.full_date;

-- =====================================================
-- TOP PERFORMERS VIEWS
-- =====================================================

-- Top 10 Products by Revenue
CREATE OR REPLACE VIEW vw_top_products AS
SELECT 
    p.product_code,
    p.product_name,
    p.category,
    p.brand,
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit
FROM dim_products p
JOIN fact_sales s ON p.product_id = s.product_id
WHERE s.order_status = 'Completed'
GROUP BY p.product_id, p.product_code, p.product_name, p.category, p.brand
ORDER BY total_revenue DESC
LIMIT 10;

-- Top 10 Customers by Revenue
CREATE OR REPLACE VIEW vw_top_customers AS
SELECT 
    c.customer_code,
    c.customer_name,
    c.customer_type,
    c.segment,
    COUNT(DISTINCT s.sale_id) AS total_orders,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit
FROM dim_customers c
JOIN fact_sales s ON c.customer_id = s.customer_id
WHERE s.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_code, c.customer_name, c.customer_type, c.segment
ORDER BY total_revenue DESC
LIMIT 10;

-- =====================================================
-- YEAR-OVER-YEAR COMPARISON
-- =====================================================

-- YoY Revenue Comparison
CREATE OR REPLACE VIEW vw_yoy_revenue_comparison AS
SELECT 
    d.year,
    d.month,
    d.month_name,
    SUM(s.total_amount) AS revenue,
    LAG(SUM(s.total_amount)) OVER (PARTITION BY d.month ORDER BY d.year) AS prev_year_revenue,
    ((SUM(s.total_amount) - LAG(SUM(s.total_amount)) OVER (PARTITION BY d.month ORDER BY d.year)) 
     / NULLIF(LAG(SUM(s.total_amount)) OVER (PARTITION BY d.month ORDER BY d.year), 0) * 100) AS yoy_growth_pct
FROM fact_sales s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.order_status = 'Completed'
GROUP BY d.year, d.month, d.month_name
ORDER BY d.year DESC, d.month DESC;