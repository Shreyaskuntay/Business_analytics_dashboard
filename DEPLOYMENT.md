# Deployment Guide

This guide covers deploying the Business Analytics Dashboard to production environments.

## 🎯 Deployment Options

### Option 1: On-Premise Server Deployment

#### Prerequisites
- Linux server (Ubuntu 20.04+ recommended)
- MySQL 8.0+
- Python 3.8+
- Tableau Server (for dashboard hosting)
- Cron for scheduling

#### Setup Steps

1. **Clone Repository**
   ```bash
   cd /opt
   sudo git clone https://github.com/yourusername/business-analytics-dashboard.git
   cd business-analytics-dashboard
   ```

2. **Install Dependencies**
   ```bash
   sudo apt update
   sudo apt install python3-pip python3-venv mysql-server
   
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Configure MySQL**
   ```bash
   sudo mysql_secure_installation
   
   mysql -u root -p
   CREATE DATABASE business_analytics;
   CREATE USER 'analytics_user'@'localhost' IDENTIFIED BY 'secure_password';
   GRANT ALL PRIVILEGES ON business_analytics.* TO 'analytics_user'@'localhost';
   FLUSH PRIVILEGES;
   ```

4. **Set Environment Variables**
   ```bash
   cp config/.env.example config/.env
   nano config/.env  # Edit with production credentials
   chmod 600 config/.env  # Secure the file
   ```

5. **Initialize Database**
   ```bash
   python scripts/setup_database.py
   ```

6. **Schedule ETL Pipeline**
   ```bash
   # Add to crontab
   crontab -e
   
   # Run daily at 2 AM
   0 2 * * * cd /opt/business-analytics-dashboard && /opt/business-analytics-dashboard/venv/bin/python scripts/run_pipeline.py --use-raw >> /var/log/etl_pipeline.log 2>&1
   ```

7. **Setup Logging**
   ```bash
   # Create log rotation
   sudo nano /etc/logrotate.d/analytics-dashboard
   
   /opt/business-analytics-dashboard/logs/*.log {
       daily
       rotate 30
       compress
       delaycompress
       notifempty
       create 0640 www-data www-data
       sharedscripts
   }
   ```

### Option 2: Cloud Deployment (AWS)

#### Architecture
- **EC2** for Python ETL processes
- **RDS MySQL** for database
- **S3** for data storage
- **CloudWatch** for monitoring
- **Lambda** for scheduled tasks (optional)

#### Setup Steps

1. **Launch RDS MySQL Instance**
   ```bash
   # Create RDS instance via AWS Console or CLI
   aws rds create-db-instance \
       --db-instance-identifier analytics-db \
       --db-instance-class db.t3.medium \
       --engine mysql \
       --master-username admin \
       --master-user-password YourPassword \
       --allocated-storage 100
   ```

2. **Launch EC2 Instance**
   ```bash
   # Ubuntu 20.04 t3.medium or larger
   # Security group: Allow SSH (22) and MySQL (3306)
   ```

3. **Configure EC2**
   ```bash
   ssh -i your-key.pem ubuntu@ec2-instance-ip
   
   # Install requirements
   sudo apt update
   sudo apt install python3-pip python3-venv git mysql-client
   
   # Clone and setup
   git clone https://github.com/yourusername/business-analytics-dashboard.git
   cd business-analytics-dashboard
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

4. **Update Environment Variables**
   ```bash
   nano config/.env
   
   DB_HOST=your-rds-endpoint.rds.amazonaws.com
   DB_PORT=3306
   DB_NAME=business_analytics
   DB_USER=admin
   DB_PASSWORD=YourPassword
   ```

5. **Setup S3 for Data Storage**
   ```bash
   # Install AWS CLI
   pip install awscli boto3
   
   # Configure credentials
   aws configure
   
   # Modify extract.py to read from S3
   import boto3
   s3 = boto3.client('s3')
   s3.download_file('your-bucket', 'data/sales.csv', 'data/raw/sales.csv')
   ```

6. **Setup CloudWatch Events**
   - Create EventBridge rule for scheduled execution
   - Target: Lambda function or EC2 instance
   - Schedule: cron(0 2 * * ? *)

### Option 3: Docker Deployment

#### Dockerfile
Create `Dockerfile`:
```dockerfile
FROM python:3.9-slim

# Install MySQL client
RUN apt-get update && apt-get install -y \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create necessary directories
RUN mkdir -p data/raw data/processed data/sample logs

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run ETL pipeline
CMD ["python", "scripts/run_pipeline.py"]
```

#### Docker Compose
Create `docker-compose.yml`:
```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: business_analytics
      MYSQL_USER: analytics_user
      MYSQL_PASSWORD: analytics_password
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database:/docker-entrypoint-initdb.d
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

  etl:
    build: .
    depends_on:
      mysql:
        condition: service_healthy
    environment:
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: business_analytics
      DB_USER: analytics_user
      DB_PASSWORD: analytics_password
    volumes:
      - ./data:/app/data
      - ./logs:/app/logs

volumes:
  mysql_data:
```

#### Deploy with Docker
```bash
# Build and run
docker-compose up -d

# Initialize database
docker-compose exec etl python scripts/setup_database.py

# Run ETL
docker-compose exec etl python scripts/run_pipeline.py
```

## 🔒 Security Best Practices

### 1. Database Security
```sql
-- Use strong passwords
-- Limit user privileges
CREATE USER 'analytics_readonly'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT ON business_analytics.* TO 'analytics_readonly'@'localhost';

-- Enable SSL/TLS
REQUIRE SSL;
```

### 2. Environment Variables
```bash
# Never commit .env files
# Use secrets management (AWS Secrets Manager, HashiCorp Vault)
echo "config/.env" >> .gitignore
```

### 3. Network Security
- Use VPC/private subnets for database
- Whitelist IP addresses
- Enable firewall rules
- Use VPN for remote access

### 4. Data Encryption
- Enable encryption at rest (RDS encryption)
- Use SSL for data in transit
- Encrypt sensitive columns

## 📊 Monitoring and Alerting

### 1. Database Monitoring
```sql
-- Create monitoring view
CREATE VIEW vw_etl_monitoring AS
SELECT 
    pipeline_name,
    stage,
    status,
    records_processed,
    start_time,
    duration_seconds,
    error_message
FROM etl_audit_log
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
ORDER BY start_time DESC;
```

### 2. Application Logging
```python
# Enhanced logging in production
import logging
from logging.handlers import RotatingFileHandler

handler = RotatingFileHandler(
    'logs/etl.log',
    maxBytes=10*1024*1024,  # 10MB
    backupCount=10
)
```

### 3. Alert Setup
- Email alerts on ETL failures
- CloudWatch alarms for AWS deployments
- Integration with PagerDuty, Slack, etc.

## 📈 Performance Optimization

### 1. Database Tuning
```sql
-- Optimize queries
ANALYZE TABLE fact_sales;
OPTIMIZE TABLE fact_sales;

-- Partition large tables
ALTER TABLE fact_sales
PARTITION BY RANGE (YEAR(created_at)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026)
);
```

### 2. ETL Optimization
- Implement incremental loads
- Use batch processing
- Parallel processing for large datasets
- Connection pooling

### 3. Caching
- Use Redis for frequently accessed data
- Tableau extract optimization
- Query result caching

## 🔄 Backup and Recovery

### 1. Database Backups
```bash
# Daily automated backups
mysqldump -u analytics_user -p business_analytics > backup_$(date +%Y%m%d).sql

# Automated backup script
0 3 * * * /usr/bin/mysqldump -u analytics_user -p'password' business_analytics | gzip > /backups/analytics_$(date +\%Y\%m\%d).sql.gz
```

### 2. Data Retention
- Keep 30 days of daily backups
- Keep 12 months of monthly backups
- Archive old data to S3 Glacier

## 📋 Maintenance Checklist

### Daily
- [ ] Monitor ETL execution logs
- [ ] Check data freshness
- [ ] Review error logs

### Weekly
- [ ] Analyze database performance
- [ ] Review slow queries
- [ ] Update documentation

### Monthly
- [ ] Backup verification
- [ ] Security audit
- [ ] Dependency updates
- [ ] Performance review

## 🚀 Scaling Strategies

### Horizontal Scaling
- Read replicas for MySQL
- Load balancer for API access
- Multiple ETL workers

### Vertical Scaling
- Increase EC2/RDS instance size
- Add more storage
- Optimize memory allocation

### Data Partitioning
- Time-based partitioning
- Geographic partitioning
- Customer segment partitioning

---

## Need Help?

Contact your DevOps team or refer to the main README.md for support resources.