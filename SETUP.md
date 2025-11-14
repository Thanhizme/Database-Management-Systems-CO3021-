# LumbarMRI Database - Quick Setup Guide

## Prerequisites Installation

### 1. Install Python Packages
```bash
pip install pyodbc pandas
```

### 2. Verify ODBC Driver
```powershell
Get-OdbcDriver | Where-Object {$_.Name -like '*SQL Server*'}
```
Should see "ODBC Driver 17 for SQL Server"

## Database Setup Steps

### Step 1: Create Database (SSMS)
```sql
CREATE DATABASE LumbarMRI;
GO
```

### Step 2: Create Schema
Option A - Using SSMS:
- Open `sql/create_schema.sql`
- Execute (F5)

Option B - Using sqlcmd:
```bash
sqlcmd -S . -d LumbarMRI -i sql/create_schema.sql
```

### Step 3: Update Data Paths
Edit `scripts/import_mri_data.py`:
```python
ROOT_DIR = r"YOUR_PATH_TO\MRI_Data\01_MRI_Data"
```

Edit `scripts/import_radiologists_data.py`:
```python
CSV_FILE = r"YOUR_PATH_TO\RadiologistsData.csv"
```

### Step 4: Run Import Scripts
```bash
# Import MRI folder structure (~2-3 minutes)
python scripts/import_mri_data.py

# Import clinical notes (~10 seconds)
python scripts/import_radiologists_data.py

# Verify data
python scripts/check_data.py
```

## Expected Results

After successful import:
- ✅ 575 Patients
- ✅ 558 Studies  
- ✅ 3,761 Series
- ✅ 48,345 Images
- ✅ 575 Radiologist Notes

## Common Issues

### Issue: pyodbc connection failed
**Solution:** Check SQL Server is running and Windows Authentication is enabled

### Issue: "Data source not found"
**Solution:** Install ODBC Driver 17:
https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

### Issue: "Login failed for user 'sa'"
**Solution:** Scripts use Windows Authentication. Remove UID/PWD from connection string.

### Issue: Import script can't find files
**Solution:** Update ROOT_DIR and CSV_FILE paths to match your system

## Testing Queries

```sql
-- Quick test
SELECT COUNT(*) FROM Patients;  -- Should be 575

-- Data integrity check
SELECT 
    (SELECT COUNT(*) FROM Patients) as Patients,
    (SELECT COUNT(*) FROM Studies) as Studies,
    (SELECT COUNT(*) FROM Series) as Series,
    (SELECT COUNT(*) FROM Images) as Images,
    (SELECT COUNT(*) FROM RadiologistsData) as Notes;
```

## Next Steps

1. Run sample queries from `sql/sample_queries.sql`
2. Review EERD diagram in `docs/`
3. Study performance optimization techniques in `docs/Implementation.txt`
