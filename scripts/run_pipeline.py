"""
ETL Pipeline Runner
Runs the ETL pipeline with optional scheduling
"""

import sys
import schedule
import time
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from etl.pipeline import run_pipeline


def run_scheduled_pipeline(data_path='data/sample'):
    """
    Run pipeline with timestamp
    
    Args:
        data_path: Path to data files
    """
    print(f"\n{'='*60}")
    print(f"Pipeline execution started at {datetime.now()}")
    print(f"{'='*60}\n")
    
    try:
        stats = run_pipeline(data_path)
        print(f"\n✓ Pipeline completed at {datetime.now()}")
        return stats
        
    except Exception as e:
        print(f"\n✗ Pipeline failed at {datetime.now()}: {str(e)}")
        return None


def schedule_pipeline(data_path='data/sample', schedule_time='02:00'):
    """
    Schedule pipeline to run at specific time
    
    Args:
        data_path: Path to data files
        schedule_time: Time to run (HH:MM format)
    """
    print(f"\nScheduling pipeline to run daily at {schedule_time}")
    print("Press Ctrl+C to stop\n")
    
    # Schedule the job
    schedule.every().day.at(schedule_time).do(run_scheduled_pipeline, data_path=data_path)
    
    # Run immediately on start
    print("Running pipeline immediately on startup...")
    run_scheduled_pipeline(data_path)
    
    # Keep running
    try:
        while True:
            schedule.run_pending()
            time.sleep(60)  # Check every minute
            
    except KeyboardInterrupt:
        print("\n\nScheduler stopped by user")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Run ETL Pipeline')
    parser.add_argument('--data-path', default='data/sample',
                       help='Path to data files (default: data/sample)')
    parser.add_argument('--schedule', choices=['daily', 'none'], default='none',
                       help='Schedule mode (default: none - run once)')
    parser.add_argument('--time', default='02:00',
                       help='Scheduled run time in HH:MM format (default: 02:00)')
    parser.add_argument('--use-raw', action='store_true',
                       help='Use data/raw instead of data/sample')
    
    args = parser.parse_args()
    
    # Determine data path
    data_path = 'data/raw' if args.use_raw else args.data_path
    
    # Create logs directory
    Path('logs').mkdir(exist_ok=True)
    
    try:
        if args.schedule == 'daily':
            schedule_pipeline(data_path, args.time)
        else:
            run_scheduled_pipeline(data_path)
            
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)