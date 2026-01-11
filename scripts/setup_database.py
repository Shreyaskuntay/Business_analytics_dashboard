"""
Database Setup Script
Initializes the database schema, views, indexes, and stored procedures
"""

import sys
import mysql.connector
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from config.database_config import db_config

def execute_sql_file(filepath, connection=None):
    """
    Execute SQL statements from a file
    
    Args:
        filepath: Path to SQL file
        connection: MySQL connection (if None, creates new connection)
    """
    close_conn = False
    
    if connection is None:
        connection = mysql.connector.connect(
            host=db_config.host,
            port=db_config.port,
            user=db_config.user,
            password=db_config.password
        )
        close_conn = True
    
    cursor = connection.cursor()
    
    # Read SQL file
    with open(filepath, 'r') as f:
        sql_content = f.read()
    
    # Split into statements and execute
    statements = sql_content.split(';')
    
    for statement in statements:
        statement = statement.strip()
        if statement and not statement.startswith('--'):
            try:
                cursor.execute(statement)
                connection.commit()
            except mysql.connector.Error as e:
                if "already exists" not in str(e):
                    print(f"Warning: {e}")
    
    cursor.close()
    
    if close_conn:
        connection.close()
    
    print(f"✓ Executed: {filepath}")


def setup_database():
    """
    Complete database setup
    """
    print("\n" + "="*60)
    print("BUSINESS ANALYTICS DATABASE SETUP")
    print("="*60 + "\n")
    
    # Base path for SQL files
    db_path = Path(__file__).parent.parent / 'database'
    
    try:
        # Step 1: Create schema and tables
        print("Step 1: Creating database schema...")
        execute_sql_file(db_path / 'schema.sql')
        
        # Connect to the newly created database
        connection = mysql.connector.connect(
            host=db_config.host,
            port=db_config.port,
            user=db_config.user,
            password=db_config.password,
            database=db_config.database
        )
        
        # Step 2: Create views
        print("\nStep 2: Creating analytics views...")
        execute_sql_file(db_path / 'views.sql', connection)
        
        # Step 3: Create indexes
        print("\nStep 3: Creating performance indexes...")
        execute_sql_file(db_path / 'indexes.sql', connection)
        
        # Step 4: Create stored procedures
        print("\nStep 4: Creating stored procedures...")
        execute_sql_file(db_path / 'stored_procedures.sql', connection)
        
        # Step 5: Populate date dimension
        print("\nStep 5: Populating date dimension...")
        populate_date_dimension(connection)
        
        connection.close()
        
        print("\n" + "="*60)
        print("✓ DATABASE SETUP COMPLETED SUCCESSFULLY")
        print("="*60 + "\n")
        
        # Verify setup
        verify_setup()
        
    except Exception as e:
        print(f"\n✗ Database setup failed: {str(e)}")
        raise


def populate_date_dimension(connection):
    """
    Populate date dimension table with dates
    
    Args:
        connection: MySQL connection
    """
    cursor = connection.cursor()
    
    # Generate dates from 2020 to 2030
    query = """
    INSERT INTO dim_date (full_date, year, quarter, month, month_name, week, 
                         day_of_month, day_of_week, day_name, is_weekend)
    SELECT 
        date_val,
        YEAR(date_val),
        QUARTER(date_val),
        MONTH(date_val),
        MONTHNAME(date_val),
        WEEK(date_val),
        DAY(date_val),
        DAYOFWEEK(date_val),
        DAYNAME(date_val),
        CASE WHEN DAYOFWEEK(date_val) IN (1, 7) THEN TRUE ELSE FALSE END
    FROM (
        SELECT DATE('2020-01-01') + INTERVAL seq DAY AS date_val
        FROM (
            SELECT @row := @row + 1 AS seq
            FROM information_schema.COLUMNS c1, information_schema.COLUMNS c2,
                 (SELECT @row := 0) r
            LIMIT 3653
        ) dates
    ) d
    WHERE date_val <= '2030-12-31'
    ON DUPLICATE KEY UPDATE date_id = date_id;
    """
    
    cursor.execute(query)
    connection.commit()
    rows = cursor.rowcount
    
    cursor.close()
    print(f"  ✓ Populated {rows} dates in date dimension")


def verify_setup():
    """
    Verify that database setup was successful
    """
    print("\n" + "="*60)
    print("VERIFYING DATABASE SETUP")
    print("="*60 + "\n")
    
    connection = db_config.get_raw_connection()
    cursor = connection.cursor(dictionary=True)
    
    # Check tables
    cursor.execute("SHOW TABLES")
    tables = [row[f'Tables_in_{db_config.database}'] for row in cursor.fetchall()]
    print(f"✓ Created {len(tables)} tables:")
    for table in sorted(tables):
        print(f"  - {table}")
    
    # Check views
    cursor.execute("""
        SELECT TABLE_NAME 
        FROM information_schema.VIEWS 
        WHERE TABLE_SCHEMA = %s
    """, (db_config.database,))
    views = [row['TABLE_NAME'] for row in cursor.fetchall()]
    print(f"\n✓ Created {len(views)} views:")
    for view in sorted(views):
        print(f"  - {view}")
    
    # Check stored procedures
    cursor.execute("""
        SELECT ROUTINE_NAME 
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = %s AND ROUTINE_TYPE = 'PROCEDURE'
    """, (db_config.database,))
    procedures = [row['ROUTINE_NAME'] for row in cursor.fetchall()]
    print(f"\n✓ Created {len(procedures)} stored procedures:")
    for proc in sorted(procedures):
        print(f"  - {proc}")
    
    # Check date dimension
    cursor.execute("SELECT COUNT(*) as cnt FROM dim_date")
    date_count = cursor.fetchone()['cnt']
    print(f"\n✓ Date dimension: {date_count} records")
    
    cursor.close()
    connection.close()
    
    print("\n" + "="*60 + "\n")


def drop_database():
    """
    Drop the database (use with caution!)
    """
    response = input(f"Are you sure you want to drop database '{db_config.database}'? (yes/no): ")
    
    if response.lower() == 'yes':
        connection = mysql.connector.connect(
            host=db_config.host,
            port=db_config.port,
            user=db_config.user,
            password=db_config.password
        )
        
        cursor = connection.cursor()
        cursor.execute(f"DROP DATABASE IF EXISTS {db_config.database}")
        connection.commit()
        cursor.close()
        connection.close()
        
        print(f"✓ Database '{db_config.database}' dropped")
    else:
        print("Operation cancelled")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Database Setup Script')
    parser.add_argument('--drop', action='store_true', 
                       help='Drop existing database before setup')
    parser.add_argument('--drop-only', action='store_true',
                       help='Only drop the database (do not recreate)')
    
    args = parser.parse_args()
    
    try:
        if args.drop_only:
            drop_database()
        else:
            if args.drop:
                drop_database()
            setup_database()
            
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)