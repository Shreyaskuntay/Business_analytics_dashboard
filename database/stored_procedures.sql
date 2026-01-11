-- Stored Procedures for Business Analytics
USE business_analytics;

DELIMITER //

-- =====================================================
-- PROCEDURE: Update Customer Lifetime Value
-- =====================================================
CREATE PROCEDURE sp_update_customer_lifetime_value()
BEGIN
    UPDATE dim_customers c
    LEFT JOIN (
        SELECT 
            customer_id,
            SUM(total_amount) AS lifetime_value
        FROM fact_sales
        WHERE order_status = 'Completed'
        GROUP BY customer_id
    ) s ON c.customer_id = s.customer_id
    SET c.lifetime_value = COALESCE(s.lifetime_value, 0);
    
    SELECT ROW_COUNT() AS customers_updated;
END //

-- =====================================================
-- PROCEDURE: Aggregate Monthly Revenue
-- =====================================================
CREATE PROCEDURE sp_aggregate_monthly_revenue(IN p_year INT, IN p_month INT)
BEGIN
    -- Delete existing records for the period
    DELETE FROM fact_revenue 
    WHERE date_id IN (
        SELECT date_id 
        FROM dim_date 
        WHERE year = p_year AND month = p_month
    );
    
    -- Insert aggregated data
    INSERT INTO fact_revenue (
        date_id,
        customer_id,
        product_id,
        sales_rep_id,
        total_orders,
        total_quantity,
        gross_revenue,
        total_discount,
        net_revenue,
        total_cost,
        total_profit,
        avg_order_value
    )
    SELECT 
        MIN(s.date_id) AS date_id,
        s.customer_id,
        s.product_id,
        s.sales_rep_id,
        COUNT(DISTINCT s.sale_id) AS total_orders,
        SUM(s.quantity) AS total_quantity,
        SUM(s.subtotal) AS gross_revenue,
        SUM(s.discount_amount) AS total_discount,
        SUM(s.total_amount) AS net_revenue,
        SUM(s.cost_amount) AS total_cost,
        SUM(s.profit_amount) AS total_profit,
        AVG(s.total_amount) AS avg_order_value
    FROM fact_sales s
    JOIN dim_date d ON s.date_id = d.date_id
    WHERE d.year = p_year 
      AND d.month = p_month
      AND s.order_status = 'Completed'
    GROUP BY s.customer_id, s.product_id, s.sales_rep_id;
    
    SELECT ROW_COUNT() AS records_created;
END //

-- =====================================================
-- PROCEDURE: Get Top Performing Products
-- =====================================================
CREATE PROCEDURE sp_get_top_products(IN p_limit INT, IN p_metric VARCHAR(20))
BEGIN
    SET @sql = CONCAT('
        SELECT 
            p.product_code,
            p.product_name,
            p.category,
            SUM(s.quantity) AS total_quantity,
            SUM(s.total_amount) AS total_revenue,
            SUM(s.profit_amount) AS total_profit
        FROM dim_products p
        JOIN fact_sales s ON p.product_id = s.product_id
        WHERE s.order_status = ''Completed''
        GROUP BY p.product_id, p.product_code, p.product_name, p.category
        ORDER BY ', p_metric, ' DESC
        LIMIT ', p_limit
    );
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //

-- =====================================================
-- PROCEDURE: Calculate YoY Growth
-- =====================================================
CREATE PROCEDURE sp_calculate_yoy_growth(IN p_year INT, IN p_month INT)
BEGIN
    SELECT 
        current.month_name,
        current.net_revenue AS current_year_revenue,
        previous.net_revenue AS previous_year_revenue,
        ((current.net_revenue - previous.net_revenue) / previous.net_revenue * 100) AS yoy_growth_pct
    FROM 
        (SELECT * FROM vw_monthly_revenue WHERE year = p_year AND month = p_month) AS current
    LEFT JOIN 
        (SELECT * FROM vw_monthly_revenue WHERE year = p_year - 1 AND month = p_month) AS previous
    ON current.month = previous.month;
END //

-- =====================================================
-- PROCEDURE: Clean Old Audit Logs
-- =====================================================
CREATE PROCEDURE sp_clean_audit_logs(IN p_days_to_keep INT)
BEGIN
    DELETE FROM etl_audit_log
    WHERE start_time < DATE_SUB(NOW(), INTERVAL p_days_to_keep DAY);
    
    SELECT ROW_COUNT() AS logs_deleted;
END //

-- =====================================================
-- PROCEDURE: Get Sales Funnel Metrics
-- =====================================================
CREATE PROCEDURE sp_get_sales_funnel()
BEGIN
    SELECT 
        'Total Orders' AS stage,
        COUNT(*) AS count,
        100.00 AS percentage
    FROM fact_sales
    
    UNION ALL
    
    SELECT 
        'Completed Orders' AS stage,
        COUNT(*) AS count,
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_sales)) AS percentage
    FROM fact_sales
    WHERE order_status = 'Completed'
    
    UNION ALL
    
    SELECT 
        'Cancelled Orders' AS stage,
        COUNT(*) AS count,
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_sales)) AS percentage
    FROM fact_sales
    WHERE order_status = 'Cancelled'
    
    UNION ALL
    
    SELECT 
        'Returned Orders' AS stage,
        COUNT(*) AS count,
        (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_sales)) AS percentage
    FROM fact_sales
    WHERE order_status = 'Returned';
END //

DELIMITER ;

-- =====================================================
-- GRANT PERMISSIONS (Adjust as needed)
-- =====================================================
-- GRANT EXECUTE ON PROCEDURE business_analytics.sp_update_customer_lifetime_value TO 'analytics_user'@'localhost';
-- GRANT EXECUTE ON PROCEDURE business_analytics.sp_aggregate_monthly_revenue TO 'analytics_user'@'localhost';