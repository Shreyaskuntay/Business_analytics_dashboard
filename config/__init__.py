"""
Configuration Package for Business Analytics Dashboard

Contains database configuration and connection management.
"""

from .database_config import DatabaseConfig, db_config

__all__ = ['DatabaseConfig', 'db_config']