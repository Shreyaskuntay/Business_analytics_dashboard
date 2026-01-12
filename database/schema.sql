-- Business Analytics Database Schema
-- Created for Business Analytics Dashboard Project

-- Drop existing database and create new
DROP DATABASE IF EXISTS business_analytics;
CREATE DATABASE business_analytics CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE business_analytics;

-- =====================================================
-- DIMENSION TABLES
-- =====================================================

-- Date Dimension Table
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY AUTO_INCREMENT,
    full_date DATE NOT NULL UNIQUE,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INT NOT NULL,
    day_of_month INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE,
    fiscal_year INT,
    fiscal_quarter INT,
    INDEX idx_full_date (full_date),
    INDEX idx_year_month (year, month),
    INDEX idx_year_quarter (year, quarter)
) ENGINE=InnoDB;

-- Customer Dimension Table
CREATE TABLE dim_customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_code VARCHAR(50) UNIQUE NOT NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_type ENUM('Individual', 'Business', 'Enterprise') NOT NULL,
    segment ENUM('Premium', 'Standard', 'Basic') NOT NULL,
    email VARCHAR(200),
    phone VARCHAR(50),
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    registration_date DATE,
    status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    lifetime_value DECIMAL(15,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customer_code (customer_code),
    INDEX idx_customer_type (customer_type),
    INDEX idx_segment (segment),
    INDEX idx_status (status),
    INDEX idx_country (country)
) ENGINE=InnoDB;

-- Product Dimension Table
CREATE TABLE dim_products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(100) NOT NULL,
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    status ENUM('Active', 'Discontinued', 'Out of Stock') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_product_code (product_code),
    INDEX idx_category (category),
    INDEX idx_subcategory (subcategory),
    INDEX idx_brand (brand),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- Sales Representative Dimension Table
CREATE TABLE dim_sales_reps (
    sales_rep_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    full_name VARCHAR(200) GENERATED ALWAYS AS (CONCAT(first_name, ' ', last_name)) STORED,
    email VARCHAR(200),
    phone VARCHAR(50),
    region VARCHAR(100),
    manager_id INT,
    hire_date DATE,
    status ENUM('Active', 'Inactive', 'On Leave') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (manager_id) REFERENCES dim_sales_reps(sales_rep_id),
    INDEX idx_employee_code (employee_code),
    INDEX idx_region (region),
    INDEX idx_status (status),
    INDEX idx_manager (manager_id)
) ENGINE=InnoDB;

-- =====================================================
-- FACT TABLES
-- =====================================================

-- Sales Fact Table
CREATE TABLE fact_sales (
    sale_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    date_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    sales_rep_id INT,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_percent DECIMAL(5,2) DEFAULT 0.00,
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    subtotal DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(10,2) DEFAULT 0.00,
    total_amount DECIMAL(15,2) NOT NULL,
    cost_amount DECIMAL(15,2) NOT NULL,
    profit_amount DECIMAL(15,2) GENERATED ALWAYS AS (total_amount - cost_amount) STORED,
    profit_margin DECIMAL(5,2) GENERATED ALWAYS AS ((total_amount - cost_amount) / total_amount * 100) STORED,
    payment_method ENUM('Credit Card', 'Debit Card', 'Cash', 'Bank Transfer', 'Other') NOT NULL,
    order_status ENUM('Pending', 'Completed', 'Cancelled', 'Returned') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (sales_rep_id) REFERENCES dim_sales_reps(sales_rep_id),
    INDEX idx_order_number (order_number),
    INDEX idx_date (date_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_sales_rep (sales_rep_id),
    INDEX idx_order_status (order_status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB;

-- Revenue Fact Table (Aggregated Monthly)
CREATE TABLE fact_revenue (
    revenue_id INT PRIMARY KEY AUTO_INCREMENT,
    date_id INT NOT NULL,
    customer_id INT,
    product_id INT,
    sales_rep_id INT,
    total_orders INT DEFAULT 0,
    total_quantity INT DEFAULT 0,
    gross_revenue DECIMAL(15,2) DEFAULT 0.00,
    total_discount DECIMAL(15,2) DEFAULT 0.00,
    net_revenue DECIMAL(15,2) DEFAULT 0.00,
    total_cost DECIMAL(15,2) DEFAULT 0.00,
    total_profit DECIMAL(15,2) DEFAULT 0.00,
    avg_order_value DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_products(product_id),
    FOREIGN KEY (sales_rep_id) REFERENCES dim_sales_reps(sales_rep_id),
    UNIQUE KEY unique_revenue_record (date_id, customer_id, product_id, sales_rep_id),
    INDEX idx_date (date_id),
    INDEX idx_customer (customer_id),
    INDEX idx_product (product_id),
    INDEX idx_sales_rep (sales_rep_id)
) ENGINE=InnoDB;

-- =====================================================
-- AUDIT TABLE
-- =====================================================

CREATE TABLE etl_audit_log (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    pipeline_name VARCHAR(100) NOT NULL,
    stage ENUM('Extract', 'Transform', 'Load') NOT NULL,
    status ENUM('Started', 'Success', 'Failed') NOT NULL,
    records_processed INT DEFAULT 0,
    error_message TEXT,
    start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NULL,
    duration_seconds INT,
    INDEX idx_pipeline (pipeline_name),
    INDEX idx_status (status),
    INDEX idx_start_time (start_time)
) ENGINE=InnoDB;