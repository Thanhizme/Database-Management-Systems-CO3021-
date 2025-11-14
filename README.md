# LumbarMRI Database Project

A relational database system for managing Lumbar Spine MRI medical imaging data and clinical notes.

## 📋 Project Overview

This database system stores and manages:
- **Patient records** (575 patients)
- **MRI Studies** (558 studies with metadata)
- **Image Series** (3,761 series with orientation classification)
- **Medical Images** (48,345 .ima files with file paths)
- **Radiologist Clinical Notes** (575 clinical assessments)

### Dataset Sources
- **MRI Images Dataset**: https://data.mendeley.com/datasets/s6bgczr8s2/2
- **Radiologists Clinical Notes Dataset**: https://data.mendeley.com/datasets/k57fr854j2/2

## 🗂️ Database Schema

### Entity Relationship
```
PATIENT (1) ──< (N) STUDY ──< (N) SERIES ──< (N) IMAGE
   │
   └── (1:1) RADIOLOGIST_DATA
```

### Tables
1. **Patients** - Patient identifiers
2. **Studies** - MRI study sessions with timestamps
3. **Series** - Image series with orientation metadata
4. **Images** - Individual image file references
5. **RadiologistsData** - Clinical notes and assessments

## 🚀 Quick Start

### Prerequisites
- SQL Server 2019+ (Windows Authentication)
- Python 3.13+
- ODBC Driver 17 for SQL Server
- Required Python packages:
  ```bash
  pip install pyodbc pandas
  ```

### Installation

1. **Create Database**
   ```sql
   CREATE DATABASE LumbarMRI;
   ```

2. **Create Schema**
   ```bash
   # Run in SSMS or sqlcmd
   sqlcmd -S . -d LumbarMRI -i sql/create_schema.sql
   ```

3. **Import MRI Data**
   ```bash
   python scripts/import_mri_data.py
   ```

4. **Import Clinical Notes**
   ```bash
   python scripts/import_radiologists_data.py
   ```

5. **Verify Import**
   ```bash
   python scripts/check_data.py
   ```

## 📊 Data Statistics

| Table | Records | Description |
|-------|---------|-------------|
| Patients | 575 | Unique patient IDs |
| Studies | 558 | MRI study sessions |
| Series | 3,761 | Image series (Sagittal, Transverse, etc.) |
| Images | 48,345 | Individual .ima file references |
| RadiologistsData | 575 | Clinical assessment notes |

### Series Orientation Distribution
- **Transverse**: 1,767 series (47%)
- **Sagittal**: 1,229 series (33%)
- **Unknown**: 758 series (20%)
- **Box**: 7 series (<1%)

## 📁 Project Structure

```
LumbarMRI-Database/
├── README.md                           # This file
├── sql/
│   ├── create_schema.sql              # Database schema DDL
│   └── sample_queries.sql             # Example queries
├── scripts/
│   ├── import_mri_data.py             # Import MRI folder structure
│   ├── import_radiologists_data.py    # Import clinical notes CSV
│   └── check_data.py                  # Data validation script
└── docs/
    ├── EERD_Diagram.png               # Entity-Relationship diagram
    ├── Implementation.txt             # Detailed implementation guide
    └── EERD_Mapping_Specification.txt # Schema mapping documentation
```

## 🔍 Sample Queries

### Find all studies for a patient
```sql
SELECT s.StudyName, s.StudyDate
FROM Patients p
JOIN Studies s ON p.PatientID = s.PatientID
WHERE p.PatientID = 1;
```

### Get sagittal series with image counts
```sql
SELECT SeriesName, FileCount
FROM Series
WHERE Orientation = 'Sagittal'
ORDER BY FileCount DESC;
```

### Join patient with clinical notes
```sql
SELECT p.PatientID, r.Note
FROM Patients p
JOIN RadiologistsData r ON p.PatientID = r.PatientID
WHERE p.PatientID = 100;
```

## 🎓 Academic Context

This project is part of the **Database Management Systems (CO3021)** course assignment for analyzing and optimizing relational databases using real-world medical imaging data.

### Key Learning Objectives
- Database schema design with weak entities
- ETL processes for heterogeneous data sources
- Query optimization and index design
- Performance analysis using execution plans

## 📝 License

This is an academic project. Dataset used for educational purposes only.

## 👥 Contributors

- Database Design & Implementation
- Academic Year 2024-2025
- Ho Chi Minh City University of Technology (HCMUT)

## 📧 Contact

For questions or issues, please open an issue on GitHub.
