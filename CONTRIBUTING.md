# Contributing to Business Analytics Dashboard

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## 🔧 Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/business-analytics-dashboard.git
   cd business-analytics-dashboard
   ```

2. **Create Virtual Environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. **Setup Development Database**
   ```bash
   # Use a separate database for development
   # Edit config/.env:
   DB_NAME=business_analytics_dev
   
   python scripts/setup_database.py
   ```

## 📝 Coding Standards

### Python Style Guide
- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/)
- Use type hints where appropriate
- Maximum line length: 100 characters
- Use docstrings for all functions and classes

### Example:
```python
def transform_data(df: pd.DataFrame, columns: List[str]) -> pd.DataFrame:
    """
    Transform DataFrame by processing specified columns.
    
    Args:
        df: Input DataFrame
        columns: List of column names to process
        
    Returns:
        Transformed DataFrame
        
    Raises:
        ValueError: If required columns are missing
    """
    pass
```

### SQL Style Guide
- Use UPPERCASE for SQL keywords
- Use snake_case for table and column names
- Add comments for complex queries
- Format multi-line queries for readability

### Example:
```sql
-- Calculate monthly revenue by customer segment
SELECT 
    c.segment,
    DATE_FORMAT(d.full_date, '%Y-%m') AS month,
    SUM(s.total_amount) AS revenue
FROM fact_sales s
JOIN dim_customers c ON s.customer_id = c.customer_id
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.order_status = 'Completed'
GROUP BY c.segment, month
ORDER BY month DESC, revenue DESC;
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_etl.py -v

# Run with coverage
pytest tests/ --cov=etl --cov-report=html
```

### Writing Tests
- Write tests for all new functionality
- Aim for >80% code coverage
- Use descriptive test names
- Mock database connections in unit tests

### Example:
```python
def test_data_extraction():
    """Test that CSV extraction works correctly"""
    extractor = DataExtractor('test_data')
    df = extractor.extract_csv('sample.csv')
    
    assert len(df) > 0
    assert 'required_column' in df.columns
```

## 📊 Database Changes

### Schema Changes
1. Update `database/schema.sql`
2. Update relevant views in `database/views.sql`
3. Update indexes in `database/indexes.sql`
4. Document changes in migration notes

### Adding New Tables
```sql
-- Add comment explaining purpose
CREATE TABLE new_table (
    id INT PRIMARY KEY AUTO_INCREMENT,
    -- Add descriptive comments
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

## 🔄 Pull Request Process

### Before Submitting
- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] No merge conflicts

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code follows style guide
```

### Commit Messages
Use clear, descriptive commit messages:
```bash
# Good
git commit -m "Add customer segmentation analysis view"
git commit -m "Fix duplicate record handling in ETL pipeline"
git commit -m "Update README with deployment instructions"

# Bad
git commit -m "Update"
git commit -m "Fix bug"
git commit -m "Changes"
```

## 🐛 Bug Reports

### Template
```markdown
**Describe the bug**
Clear description of the issue

**To Reproduce**
Steps to reproduce:
1. Go to '...'
2. Click on '...'
3. See error

**Expected behavior**
What should happen

**Actual behavior**
What actually happens

**Environment**
- OS: [e.g., Ubuntu 20.04]
- Python version: [e.g., 3.9.5]
- MySQL version: [e.g., 8.0.25]

**Additional context**
Any other relevant information
```

## ✨ Feature Requests

### Template
```markdown
**Feature Description**
Clear description of the proposed feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches considered

**Additional Context**
Any other relevant information
```

## 📚 Documentation

### Update Documentation When:
- Adding new features
- Changing existing behavior
- Updating dependencies
- Modifying configuration

### Documentation Locations
- **README.md**: Project overview and quick start
- **SETUP_GUIDE.md**: Detailed setup instructions
- **DEPLOYMENT.md**: Production deployment guide
- **INTERVIEW_GUIDE.md**: Interview presentation tips
- **Code comments**: Inline documentation

## 🎯 Areas for Contribution

### Good First Issues
- Adding more unit tests
- Improving documentation
- Adding sample data generators
- Creating additional views

### Advanced Contributions
- Performance optimizations
- New data sources integration
- Advanced analytics features
- Cloud deployment automation
- CI/CD pipeline setup

## 🤝 Code Review Process

### As a Reviewer
- Be constructive and respectful
- Explain the "why" behind suggestions
- Approve when standards are met
- Test the changes locally when possible

### As a Contributor
- Respond to feedback promptly
- Ask for clarification when needed
- Make requested changes
- Thank reviewers for their time

## 📧 Getting Help

- **Issues**: Open an issue for bugs or questions
- **Discussions**: Use for general questions
- **Email**: contact@example.com for private matters

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Business Analytics Dashboard! 🎉