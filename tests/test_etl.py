"""
Unit tests for ETL modules
"""

import pytest
import pandas as pd
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).parent.parent))

from etl.extract import DataExtractor
from etl.transform import DataTransformer, transform_sales_data
from etl.load import DataLoader


class TestDataExtractor:
    """Test data extraction functionality"""
    
    def test_extractor_initialization(self):
        """Test extractor creates output path"""
        extractor = DataExtractor('test_data')
        assert Path('test_data').exists()
        Path('test_data').rmdir()
    
    def test_validate_data_empty(self):
        """Test validation with empty DataFrame"""
        extractor = DataExtractor()
        df = pd.DataFrame()
        assert not extractor.validate_data(df)
    
    def test_validate_data_with_required_columns(self):
        """Test validation with required columns"""
        extractor = DataExtractor()
        df = pd.DataFrame({'col1': [1, 2], 'col2': [3, 4]})
        
        # Should pass with present columns
        assert extractor.validate_data(df, required_columns=['col1'])
        
        # Should fail with missing columns
        assert not extractor.validate_data(df, required_columns=['col3'])
    
    def test_get_data_info(self):
        """Test data info extraction"""
        extractor = DataExtractor()
        df = pd.DataFrame({'col1': [1, 2, None], 'col2': ['a', 'b', 'c']})
        info = extractor.get_data_info(df)
        
        assert info['rows'] == 3
        assert info['columns'] == 2
        assert 'col1' in info['column_names']
        assert info['null_counts']['col1'] == 1


class TestDataTransformer:
    """Test data transformation functionality"""
    
    def test_clean_column_names(self):
        """Test column name cleaning"""
        transformer = DataTransformer()
        df = pd.DataFrame({'Column Name': [1], 'Another-Column': [2]})
        df = transformer.clean_column_names(df)
        
        assert 'column_name' in df.columns
        assert 'anothercolumn' in df.columns
    
    def test_remove_duplicates(self):
        """Test duplicate removal"""
        transformer = DataTransformer()
        df = pd.DataFrame({
            'id': [1, 2, 2, 3],
            'value': ['a', 'b', 'b', 'c']
        })
        df = transformer.remove_duplicates(df, subset=['id'])
        
        assert len(df) == 3
    
    def test_convert_data_types(self):
        """Test data type conversion"""
        transformer = DataTransformer()
        df = pd.DataFrame({'col1': ['1', '2', '3']})
        df = transformer.convert_data_types(df, {'col1': 'int64'})
        
        assert df['col1'].dtype == 'int64'
    
    def test_transform_sales_data(self):
        """Test sales data transformation"""
        df = pd.DataFrame({
            'Order Number': ['ORD001', 'ORD002', 'ORD001'],
            'Quantity': [2, 3, 2],
            'Unit Price': [100.50, 200.00, 100.50],
            'Order Date': ['2024-01-15', '2024-01-16', '2024-01-15']
        })
        
        transformed = transform_sales_data(df)
        
        # Should remove duplicate based on order_number
        assert len(transformed) == 2
        # Should have lowercase column names
        assert 'order_number' in transformed.columns


class TestDataLoader:
    """Test data loading functionality"""
    
    def test_loader_initialization(self):
        """Test loader creates engine"""
        loader = DataLoader()
        assert loader.engine is not None
    
    # Note: Database connection tests require a running MySQL instance
    # and proper configuration, so they're skipped in unit tests


def test_pipeline_integration():
    """Integration test for the complete pipeline"""
    # This would test the full pipeline flow
    # Requires database setup and sample data
    pass


if __name__ == "__main__":
    pytest.main([__file__, '-v'])