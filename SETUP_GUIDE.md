# Business Analytics Dashboard - Complete Setup Guide

This guide will walk you through setting up the entire Business Analytics Dashboard project from scratch.

## 📋 Prerequisites

### Required Software
- **Python 3.8+** - [Download](https://www.python.org/downloads/)
- **MySQL 8.0+** - [Download](https://dev.mysql.com/downloads/mysql/)
- **Tableau Desktop** (optional) - For dashboard development
- **Git** - For version control

### Verify Installations
```bash
python --version  # Should be 3.8 or higher
mysql --version   # Should be 8.0 or higher
git --version
```

## 🚀 Step-by-Step Setup

### Step 1: Clone or Create Repository

**Option A: Clone from GitHub** (if already uploaded)
```bash
git clone https://github.com/yourusername/business-analytics-dashboard.git
cd business-analytics-dashboard
```

**Option B: Create New Repository**
```bash
mkdir business-analytics-dashboard
cd business-analytics-dashboard
git init
```

### Step 2: Create Project Structure

Create all necessary directories:
```bash
# Windows
mkdir data\raw data\processed data\sample database etl config scripts tableau\dashboards tableau\data_sources logs tests

# macOS/Linux
mkdir -p data/{raw,processed,sample} database etl config scripts tableau/{dashboards,data_sources} logs tests
```

Add `.gitkeep` files to preserve empty directories:
```bash
# Windows
type nul > data\raw\.gitkeep
type nul > data\processed\.gitkeep
type nul > logs\.gitkeep

# macOS/Linux
touch data/raw/.gitkeep data/processed/.gitkeep logs/.gitkeep
```

### Step 3: Set Up Python Environment

Create and activate virtual environment:
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python -m venv venv
source venv/bin/activate
```

Install dependencies:
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 4: Configure MySQL Database

1. **Start MySQL Server**
   ```bash
   # Check if MySQL is running
   # Windows: Check Services
   # macOS: brew services start mysql
   # Linux: sudo systemctl start mysql
   ```

2. **Create Database User** (Optional but recommended)
   ```sql
   mysql -u root -p
   
   CREATE USER 'analytics_user'@'localhost' IDENTIFIED BY 'your_password';
   GRANT ALL PRIVILEGES ON business_analytics.* TO 'analytics_user'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```

### Step 5: Configure Environment Variables

1. Copy the example environment file:
   ```bash
   # Windows
   copy config\.env.example config\.env
   
   # macOS/Linux
   cp config/.env.example config/.env
   ```

2. Edit `config/.env` with your database credentials:
   ```env
   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=business_analytics
   DB_USER=analytics_user
   DB_PASSWORD=your_password
   ```

### Step 6: Initialize Database

Run the database setup script:
```bash
python scripts/setup_database.py
```

This will:
- Create the database schema
- Create all tables (dimension and fact tables)
- Create analytics views
- Create performance indexes
- Create stored procedures
- Populate the date dimension

Expected output:
```
============================================================
BUSINESS ANALYTICS DATABASE SETUP
============================================================

Step 1: Creating database schema...
✓ Executed: database/schema.sql

Step 2: Creating analytics views...
✓ Executed: database/views.sql

...

✓ DATABASE SETUP COMPLETED SUCCESSFULLY
```

### Step 7: Generate Sample Data

Generate realistic sample data for testing:
```bash
python scripts/generate_sample_data.py
```

Optional: Customize the amount of data:
```bash
python scripts/generate_sample_data.py --customers 1000 --products 300 --transactions 10000
```

This creates CSV files in `data/sample/`:
- `customers.csv`
- `products.csv`
- `sales_reps.csv`
- `sales_transactions.csv`

### Step 8: Run ETL Pipeline

Execute the ETL pipeline to load data into the database:
```bash
python scripts/run_pipeline.py
```

The pipeline will:
1. **Extract** data from CSV files
2. **Transform** and clean the data
3. **Load** into MySQL database

Expected output:
```
============================================================
STAGE 1: EXTRACT
============================================================
Extracting data from data/sample/sales_transactions.csv
Successfully extracted 5000 records...

============================================================
STAGE 2: TRANSFORM
============================================================
Sales transformation complete...

============================================================
STAGE 3: LOAD
============================================================
Loading dimension tables...
Loading fact tables...

✓ Pipeline completed successfully!
```

### Step 9: Verify Data Load

Connect to MySQL and verify:
```bash
mysql -u analytics_user -p business_analytics
```

Run verification queries:
```sql
-- Check record counts
SELECT 'Customers' as Table_Name, COUNT(*) as Record_Count FROM dim_customers
UNION ALL
SELECT 'Products', COUNT(*) FROM dim_products
UNION ALL
SELECT 'Sales Reps', COUNT(*) FROM dim_sales_reps
UNION ALL
SELECT 'Sales', COUNT(*) FROM fact_sales;

-- Check sample data
SELECT * FROM vw_monthly_revenue LIMIT 10;
SELECT * FROM vw_customer_metrics LIMIT 10;
SELECT * FROM vw_product_performance LIMIT 10;
```

### Step 10: Connect Tableau (Optional)

1. **Open Tableau Desktop**

2. **Connect to MySQL**
   - Server: localhost
   - Port: 3306
   - Database: business_analytics
   - Username: analytics_user
   - Password: your_password

3. **Create Data Sources**
   - Drag tables/views into the canvas
   - Create relationships between dimension and fact tables
   - Save as `.tds` files in `tableau/data_sources/`

4. **Build Dashboards**
   - Create visualizations
   - Combine into interactive dashboards
   - Save workbooks in `tableau/dashboards/`

## 🔄 Running the Pipeline Regularly

### One-Time Execution
```bash
python scripts/run_pipeline.py
```

### Scheduled Execution (Daily at 2 AM)
```bash
python scripts/run_pipeline.py --schedule daily --time 02:00
```

### Use Different Data Source
```bash
# Use data from data/raw instead of data/sample
python scripts/run_pipeline.py --use-raw
```

## 🧪 Running Tests

Execute unit tests:
```bash
# Run all tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=etl --cov-report=html
```

## 📊 Accessing Analytics

### Via MySQL Queries
```sql
-- Executive KPI Summary
SELECT * FROM vw_kpi_summary;

-- Monthly Revenue Trend
SELECT * FROM vw_monthly_revenue ORDER BY year DESC, month DESC;

-- Top Performing Products
SELECT * FROM vw_product_performance ORDER BY total_revenue DESC LIMIT 10;

-- Customer Segmentation
SELECT * FROM vw_customer_segmentation;
```

### Via Stored Procedures
```sql
-- Get top 10 products by revenue
CALL sp_get_top_products(10, 'total_revenue');

-- Calculate YoY growth
CALL sp_calculate_yoy_growth(2024, 12);

-- Update customer lifetime values
CALL sp_update_customer_lifetime_value();
```

## 🔧 Troubleshooting

### Database Connection Issues
```bash
# Test database connection
python -c "from config.database_config import db_config; print('Connected!' if db_config.test_connection() else 'Failed')"
```

### Missing Dependencies
```bash
pip install -r requirements.txt --upgrade
```

### Permission Issues
```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON business_analytics.* TO 'analytics_user'@'localhost';
FLUSH PRIVILEGES;
```

### Data Loading Errors
```bash
# Check ETL logs
cat logs/etl_pipeline.log  # macOS/Linux
type logs\etl_pipeline.log  # Windows

# Check audit table
mysql -u analytics_user -p -e "SELECT * FROM business_analytics.etl_audit_log ORDER BY start_time DESC LIMIT 10;"
```

## 📁 Adding Your Own Data

1. **Place CSV files in `data/raw/`**
   - Ensure column names match the expected format
   - Required files: customers.csv, products.csv, sales_transactions.csv

2. **Update transformation logic if needed**
   - Edit `etl/transform.py` for custom business logic
   - Add new calculated fields
   - Modify data cleaning rules

3. **Run the pipeline**
   ```bash
   python scripts/run_pipeline.py --use-raw
   ```

## 🎯 Next Steps

1. **Customize Dashboards** - Build Tableau visualizations specific to your needs
2. **Add More Data Sources** - Integrate APIs, databases, or other files
3. **Implement Incremental Loads** - Modify ETL to process only new/changed data
4. **Deploy to Production** - Set up on a server with scheduled jobs
5. **Add Security** - Implement proper authentication and authorization

## 📚 Additional Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [Tableau Learning](https://www.tableau.com/learn)
- [Python pandas](https://pandas.pydata.org/docs/)
- [SQLAlchemy](https://docs.sqlalchemy.org/)

## 🤝 Need Help?

- Check the logs in `logs/etl_pipeline.log`
- Review audit records in `etl_audit_log` table
- Ensure all prerequisites are installed
- Verify database credentials in `config/.env`

---

**You're all set!** The Business Analytics Dashboard is ready for use and further customization.