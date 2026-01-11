"""
Data Extraction Module
Extracts data from various sources (CSV, Excel, APIs)
"""

import pandas as pd
import os
import logging
from pathlib import Path
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DataExtractor:
    """Handles data extraction from various sources"""
    
    def __init__(self, data_path='data/raw'):
        self.data_path = Path(data_path)
        self.data_path.mkdir(parents=True, exist_ok=True)
        
    def extract_csv(self, filename, **kwargs):
        """
        Extract data from CSV file
        
        Args:
            filename: Name of CSV file
            **kwargs: Additional arguments for pd.read_csv
            
        Returns:
            DataFrame with extracted data
        """
        try:
            filepath = self.data_path / filename
            logger.info(f"Extracting data from {filepath}")
            
            df = pd.read_csv(filepath, **kwargs)
            logger.info(f"Successfully extracted {len(df)} records from {filename}")
            
            return df
            
        except FileNotFoundError:
            logger.error(f"File not found: {filepath}")
            raise
        except Exception as e:
            logger.error(f"Error extracting CSV {filename}: {str(e)}")
            raise
    
    def extract_excel(self, filename, sheet_name=0, **kwargs):
        """
        Extract data from Excel file
        
        Args:
            filename: Name of Excel file
            sheet_name: Sheet name or index
            **kwargs: Additional arguments for pd.read_excel
            
        Returns:
            DataFrame with extracted data
        """
        try:
            filepath = self.data_path / filename
            logger.info(f"Extracting data from {filepath}, sheet: {sheet_name}")
            
            df = pd.read_excel(filepath, sheet_name=sheet_name, **kwargs)
            logger.info(f"Successfully extracted {len(df)} records from {filename}")
            
            return df
            
        except FileNotFoundError:
            logger.error(f"File not found: {filepath}")
            raise
        except Exception as e:
            logger.error(f"Error extracting Excel {filename}: {str(e)}")
            raise
    
    def extract_multiple_csvs(self, pattern='*.csv'):
        """
        Extract data from multiple CSV files matching a pattern
        
        Args:
            pattern: File pattern to match
            
        Returns:
            Dictionary of DataFrames
        """
        data_dict = {}
        
        try:
            files = list(self.data_path.glob(pattern))
            logger.info(f"Found {len(files)} files matching pattern: {pattern}")
            
            for filepath in files:
                filename = filepath.name
                data_dict[filename] = pd.read_csv(filepath)
                logger.info(f"Extracted {len(data_dict[filename])} records from {filename}")
            
            return data_dict
            
        except Exception as e:
            logger.error(f"Error extracting multiple CSVs: {str(e)}")
            raise
    
    def validate_data(self, df, required_columns=None):
        """
        Validate extracted data
        
        Args:
            df: DataFrame to validate
            required_columns: List of required column names
            
        Returns:
            Boolean indicating validation success
        """
        if df is None or df.empty:
            logger.warning("DataFrame is empty")
            return False
        
        if required_columns:
            missing_columns = set(required_columns) - set(df.columns)
            if missing_columns:
                logger.error(f"Missing required columns: {missing_columns}")
                return False
        
        logger.info(f"Data validation passed. Shape: {df.shape}")
        return True
    
    def get_data_info(self, df):
        """
        Get information about extracted data
        
        Args:
            df: DataFrame to analyze
            
        Returns:
            Dictionary with data information
        """
        info = {
            'rows': len(df),
            'columns': len(df.columns),
            'column_names': list(df.columns),
            'dtypes': df.dtypes.to_dict(),
            'null_counts': df.isnull().sum().to_dict(),
            'memory_usage': df.memory_usage(deep=True).sum() / 1024**2  # MB
        }
        
        return info


def extract_sales_data(data_path='data/raw'):
    """
    Extract sales data from CSV files
    
    Returns:
        Dictionary containing all extracted DataFrames
    """
    extractor = DataExtractor(data_path)
    
    data = {}
    
    try:
        # Extract sales transactions
        if (extractor.data_path / 'sales_transactions.csv').exists():
            data['sales'] = extractor.extract_csv('sales_transactions.csv')
            logger.info(f"Extracted sales: {data['sales'].shape}")
        
        # Extract customer data
        if (extractor.data_path / 'customers.csv').exists():
            data['customers'] = extractor.extract_csv('customers.csv')
            logger.info(f"Extracted customers: {data['customers'].shape}")
        
        # Extract product data
        if (extractor.data_path / 'products.csv').exists():
            data['products'] = extractor.extract_csv('products.csv')
            logger.info(f"Extracted products: {data['products'].shape}")
        
        # Extract sales rep data
        if (extractor.data_path / 'sales_reps.csv').exists():
            data['sales_reps'] = extractor.extract_csv('sales_reps.csv')
            logger.info(f"Extracted sales reps: {data['sales_reps'].shape}")
        
        logger.info(f"Extraction complete. Total datasets: {len(data)}")
        return data
        
    except Exception as e:
        logger.error(f"Error in extract_sales_data: {str(e)}")
        raise


if __name__ == "__main__":
    # Test extraction
    try:
        data = extract_sales_data()
        for name, df in data.items():
            print(f"\n{name.upper()}:")
            print(df.head())
            print(f"Shape: {df.shape}")
    except Exception as e:
        print(f"Extraction failed: {e}")