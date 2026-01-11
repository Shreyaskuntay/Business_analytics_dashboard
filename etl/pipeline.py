"""
ETL Pipeline Orchestrator
Coordinates Extract, Transform, and Load processes
"""

import logging
from datetime import datetime
import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from etl.extract import extract_sales_data
from etl.transform import (transform_sales_data, transform_customer_data,
                           transform_product_data, transform_sales_rep_data)
from etl.load import DataLoader, load_dimension_tables, load_fact_sales

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/etl_pipeline.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class ETLPipeline:
    """Main ETL pipeline orchestrator"""
    
    def __init__(self, pipeline_name='sales_etl'):
        self.pipeline_name = pipeline_name
        self.loader = DataLoader()
        self.start_time = None
        self.stats = {
            'extract': {'status': 'Not Started', 'records': 0},
            'transform': {'status': 'Not Started', 'records': 0},
            'load': {'status': 'Not Started', 'records': 0}
        }
    
    def run(self, data_path='data/raw'):
        """
        Execute complete ETL pipeline
        
        Args:
            data_path: Path to raw data files
            
        Returns:
            Dictionary with pipeline statistics
        """
        self.start_time = datetime.now()
        logger.info(f"Starting ETL pipeline: {self.pipeline_name}")
        
        try:
            # EXTRACT
            logger.info("=" * 60)
            logger.info("STAGE 1: EXTRACT")
            logger.info("=" * 60)
            
            self.loader.log_etl_audit(
                self.pipeline_name, 'Extract', 'Started', 
                start_time=self.start_time
            )
            
            raw_data = self._extract(data_path)
            
            self.loader.log_etl_audit(
                self.pipeline_name, 'Extract', 'Success',
                records_processed=sum(len(df) for df in raw_data.values()),
                start_time=self.start_time
            )
            
            # TRANSFORM
            logger.info("=" * 60)
            logger.info("STAGE 2: TRANSFORM")
            logger.info("=" * 60)
            
            transform_start = datetime.now()
            self.loader.log_etl_audit(
                self.pipeline_name, 'Transform', 'Started',
                start_time=transform_start
            )
            
            transformed_data = self._transform(raw_data)
            
            self.loader.log_etl_audit(
                self.pipeline_name, 'Transform', 'Success',
                records_processed=sum(len(df) for df in transformed_data.values()),
                start_time=transform_start
            )
            
            # LOAD
            logger.info("=" * 60)
            logger.info("STAGE 3: LOAD")
            logger.info("=" * 60)
            
            load_start = datetime.now()
            self.loader.log_etl_audit(
                self.pipeline_name, 'Load', 'Started',
                start_time=load_start
            )
            
            load_results = self._load(transformed_data)
            
            self.loader.log_etl_audit(
                self.pipeline_name, 'Load', 'Success',
                records_processed=sum(load_results.values()),
                start_time=load_start
            )
            
            # Pipeline completed
            duration = (datetime.now() - self.start_time).total_seconds()
            logger.info("=" * 60)
            logger.info(f"ETL PIPELINE COMPLETED in {duration:.2f} seconds")
            logger.info("=" * 60)
            
            self._print_summary()
            
            return self.stats
            
        except Exception as e:
            logger.error(f"ETL pipeline failed: {str(e)}", exc_info=True)
            
            # Log failure
            failed_stage = None
            if self.stats['extract']['status'] != 'Success':
                failed_stage = 'Extract'
            elif self.stats['transform']['status'] != 'Success':
                failed_stage = 'Transform'
            else:
                failed_stage = 'Load'
            
            self.loader.log_etl_audit(
                self.pipeline_name, failed_stage, 'Failed',
                error_message=str(e),
                start_time=self.start_time
            )
            
            raise
    
    def _extract(self, data_path):
        """
        Extract stage
        
        Args:
            data_path: Path to raw data
            
        Returns:
            Dictionary of raw DataFrames
        """
        try:
            raw_data = extract_sales_data(data_path)
            
            total_records = sum(len(df) for df in raw_data.values())
            self.stats['extract'] = {
                'status': 'Success',
                'records': total_records,
                'datasets': list(raw_data.keys())
            }
            
            logger.info(f"Extraction complete: {len(raw_data)} datasets, {total_records} records")
            return raw_data
            
        except Exception as e:
            self.stats['extract']['status'] = 'Failed'
            logger.error(f"Extraction failed: {str(e)}")
            raise
    
    def _transform(self, raw_data):
        """
        Transform stage
        
        Args:
            raw_data: Dictionary of raw DataFrames
            
        Returns:
            Dictionary of transformed DataFrames
        """
        try:
            transformed_data = {}
            
            # Transform each dataset
            if 'sales' in raw_data:
                transformed_data['sales'] = transform_sales_data(raw_data['sales'])
                logger.info(f"Transformed sales: {len(transformed_data['sales'])} records")
            
            if 'customers' in raw_data:
                transformed_data['customers'] = transform_customer_data(raw_data['customers'])
                logger.info(f"Transformed customers: {len(transformed_data['customers'])} records")
            
            if 'products' in raw_data:
                transformed_data['products'] = transform_product_data(raw_data['products'])
                logger.info(f"Transformed products: {len(transformed_data['products'])} records")
            
            if 'sales_reps' in raw_data:
                transformed_data['sales_reps'] = transform_sales_rep_data(raw_data['sales_reps'])
                logger.info(f"Transformed sales_reps: {len(transformed_data['sales_reps'])} records")
            
            total_records = sum(len(df) for df in transformed_data.values())
            self.stats['transform'] = {
                'status': 'Success',
                'records': total_records,
                'datasets': list(transformed_data.keys())
            }
            
            logger.info(f"Transformation complete: {total_records} records")
            return transformed_data
            
        except Exception as e:
            self.stats['transform']['status'] = 'Failed'
            logger.error(f"Transformation failed: {str(e)}")
            raise
    
    def _load(self, transformed_data):
        """
        Load stage
        
        Args:
            transformed_data: Dictionary of transformed DataFrames
            
        Returns:
            Dictionary with load results
        """
        try:
            load_results = {}
            
            # Load dimension tables first
            dimension_data = {
                k: v for k, v in transformed_data.items() 
                if k in ['customers', 'products', 'sales_reps']
            }
            
            if dimension_data:
                dim_results = load_dimension_tables(dimension_data)
                load_results.update(dim_results)
                logger.info(f"Dimension tables loaded: {dim_results}")
            
            # Load fact tables
            if 'sales' in transformed_data:
                sales_loaded = load_fact_sales(transformed_data['sales'])
                load_results['sales'] = sales_loaded
                logger.info(f"Sales facts loaded: {sales_loaded} records")
            
            total_records = sum(load_results.values())
            self.stats['load'] = {
                'status': 'Success',
                'records': total_records,
                'tables': list(load_results.keys())
            }
            
            logger.info(f"Load complete: {total_records} records loaded")
            return load_results
            
        except Exception as e:
            self.stats['load']['status'] = 'Failed'
            logger.error(f"Load failed: {str(e)}")
            raise
    
    def _print_summary(self):
        """Print pipeline execution summary"""
        print("\n" + "=" * 60)
        print("ETL PIPELINE SUMMARY")
        print("=" * 60)
        print(f"Pipeline: {self.pipeline_name}")
        print(f"Start Time: {self.start_time}")
        print(f"Duration: {(datetime.now() - self.start_time).total_seconds():.2f} seconds")
        print("\nStage Results:")
        print("-" * 60)
        
        for stage, info in self.stats.items():
            print(f"{stage.upper():12} | Status: {info['status']:10} | Records: {info['records']:,}")
        
        print("=" * 60 + "\n")


def run_pipeline(data_path='data/raw'):
    """
    Convenience function to run the ETL pipeline
    
    Args:
        data_path: Path to raw data files
        
    Returns:
        Pipeline statistics
    """
    pipeline = ETLPipeline(pipeline_name='sales_analytics_etl')
    return pipeline.run(data_path)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='Run ETL Pipeline')
    parser.add_argument('--data-path', default='data/raw', 
                       help='Path to raw data files')
    parser.add_argument('--pipeline-name', default='sales_analytics_etl',
                       help='Name of the pipeline')
    
    args = parser.parse_args()
    
    # Create logs directory if it doesn't exist
    Path('logs').mkdir(exist_ok=True)
    
    # Run pipeline
    try:
        pipeline = ETLPipeline(pipeline_name=args.pipeline_name)
        stats = pipeline.run(data_path=args.data_path)
        print("\n✓ Pipeline completed successfully!")
        
    except Exception as e:
        print(f"\n✗ Pipeline failed: {str(e)}")
        sys.exit(1)