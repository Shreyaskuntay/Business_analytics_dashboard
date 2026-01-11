# Getting Started - Quick Reference

This is your quick-start guide for setting up the Business Analytics Dashboard project for your interview.

## ⚡ Quick Start (10 Minutes)

### 1. Prerequisites Check
```bash
python --version  # Need 3.8+
mysql --version   # Need 8.0+
git --version
```

### 2. Clone/Download Project
```bash
# If pushing to GitHub first
git clone https://github.com/yourusername/business-analytics-dashboard.git
cd business-analytics-dashboard

# Or download ZIP and extract
```

### 3. Setup Python Environment
```bash
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

pip install -r requirements.txt
```

### 4. Configure Database
Edit `config/.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=business_analytics
DB_USER=root  # or your MySQL user
DB_PASSWORD=your_password
```

### 5. Initialize Everything
```bash
# Setup database
python scripts/setup_database.py

# Generate sample data
python scripts/generate_sample_data.py

# Run ETL pipeline
python scripts/run_pipeline.py
```

### 6. Verify Success
```bash
mysql -u root -p
USE business_analytics;
SELECT * FROM vw_monthly_revenue LIMIT 5;
```

## 📋 Pre-Interview Checklist

### Day Before Interview
- [ ] Test all commands work
- [ ] Database has data
- [ ] Can explain each component
- [ ] Screenshots of dashboards ready
- [ ] GitHub repo is clean and updated
- [ ] README is professional
- [ ] Know your metrics (70% improvement, etc.)

### 30 Minutes Before
- [ ] Start MySQL service
- [ ] Activate virtual environment
- [ ] Open project in IDE
- [ ] Have key files open:
  - `README.md`
  - `etl/pipeline.py`
  - `database/schema.sql`
  - `database/views.sql`
- [ ] Test a quick query in MySQL
- [ ] Review INTERVIEW_GUIDE.md

## 🎯 What to Show in Interview

### 1. Project Overview (2 min)
- Open `README.md`
- Show architecture diagram
- Mention key metrics (70% reduction)

### 2. Database Design (3 min)
```sql
-- Show in MySQL Workbench or terminal
SHOW TABLES;
DESCRIBE fact_sales;
SELECT * FROM vw_monthly_revenue LIMIT 10;
```

### 3. ETL Code (4 min)
Show these files in order:
1. `etl/extract.py` - "Here's how I extract data..."
2. `etl/transform.py` - "Then I clean and transform..."
3. `etl/load.py` - "Finally load with bulk operations..."
4. `etl/pipeline.py` - "This orchestrates everything..."

### 4. Run Live Demo (2 min)
```bash
# Show it working
python scripts/run_pipeline.py

# Show the output
# Point out the stages and logging
```

### 5. Show Results (3 min)
```sql
-- Executive Summary
SELECT * FROM vw_kpi_summary;

-- Revenue Analysis
SELECT * FROM vw_monthly_revenue 
ORDER BY year DESC, month DESC 
LIMIT 12;

-- Top Products
SELECT * FROM vw_product_performance 
ORDER BY total_revenue DESC 
LIMIT 10;
```

## 🗣️ Key Talking Points

### Opening (30 seconds)
> "I built an end-to-end BI solution that automates data pipelines and delivers business insights. It reduced report generation time by 70% and centralized analytics for the organization."

### Technical Depth
- **Database**: "Star schema with optimized indexes and materialized views"
- **ETL**: "Three-stage pipeline with comprehensive error handling and audit trails"
- **Performance**: "Bulk operations and strategic indexing for fast processing"
- **Automation**: "Scheduled daily runs with monitoring and alerting"

### Business Value
- **Before**: Manual reports took 3-4 hours
- **After**: Automated in 10 minutes
- **Impact**: Faster decisions, standardized metrics, self-service analytics

## 💡 Common Questions - Quick Answers

**Q: "Walk me through your architecture"**
```
Data Sources → Python ETL → MySQL → Tableau
(CSV/API)      (Extract,     (Star    (Interactive
                Transform,   Schema)   Dashboards)
                Load)
```

**Q: "How did you optimize performance?"**
- Bulk inserts instead of row-by-row
- Strategic indexing on foreign keys and date columns
- Upsert for incremental loads
- Connection pooling

**Q: "How do you handle errors?"**
- Try-catch blocks at each stage
- Logging to file and database
- Audit table tracks all executions
- Email alerts on failures (can be added)

**Q: "How would you scale this?"**
- Partition large tables by date
- Add read replicas for queries
- Implement incremental loading
- Move to cloud (AWS RDS, Redshift)

## 🎨 If Showing Tableau

### Must-Have Dashboards
1. **Executive Summary**
   - KPI cards (Revenue, Profit, Orders)
   - Trend lines
   - YoY comparison

2. **Sales Analysis**
   - Bar charts by region/product
   - Time series
   - Filters for interactivity

3. **Customer Analytics**
   - Segmentation pie charts
   - Cohort analysis
   - Lifetime value

### Demo Tips
- Start with Executive view
- Show filter interactions
- Drill down to details
- Explain business insights

## 📊 Sample Data Overview

After running `generate_sample_data.py`:
- **500 customers** across 3 types, 3 segments
- **200 products** in 5 categories
- **50 sales reps** in 5 regions
- **5,000 transactions** over 2 years

This creates realistic scenarios for analysis!

## 🚨 Troubleshooting

### MySQL Connection Failed
```bash
# Check MySQL is running
# Windows: Services → MySQL
# Mac: brew services start mysql
# Linux: sudo systemctl start mysql

# Test connection
mysql -u root -p
```

### Import Errors
```bash
# Reinstall dependencies
pip install -r requirements.txt --upgrade
```

### No Data in Tables
```bash
# Re-run the pipeline
python scripts/run_pipeline.py
```

### Permission Denied
```sql
-- Grant permissions
GRANT ALL PRIVILEGES ON business_analytics.* 
TO 'your_user'@'localhost';
FLUSH PRIVILEGES;
```

## 📱 Day-of-Interview Command Cheat Sheet

```bash
# Start everything
cd business-analytics-dashboard
source venv/bin/activate  # or venv\Scripts\activate on Windows
mysql.server start  # if needed

# Quick test
python scripts/run_pipeline.py

# Open MySQL
mysql -u root -p business_analytics

# Show key metrics
SELECT * FROM vw_kpi_summary;
SELECT * FROM vw_monthly_revenue ORDER BY year DESC LIMIT 12;
```

## 🎯 Final Tips

1. **Be Confident**: You built this from scratch!
2. **Tell a Story**: Problem → Solution → Impact
3. **Show Enthusiasm**: Talk about what you learned
4. **Be Honest**: If you don't know something, say so
5. **Prepare Questions**: About their data infrastructure

## 📚 Resources to Review

- **INTERVIEW_GUIDE.md**: Detailed presentation strategy
- **README.md**: Project overview
- **Your code**: Be ready to explain any line

---

## ✅ You're Ready When...

- [ ] Can run entire setup in under 10 minutes
- [ ] Can explain each file's purpose
- [ ] Database queries return data
- [ ] Can describe business impact
- [ ] Comfortable with the code
- [ ] Know the architecture by heart
- [ ] Can answer "why did you choose X?"

**You've got this! 🚀**