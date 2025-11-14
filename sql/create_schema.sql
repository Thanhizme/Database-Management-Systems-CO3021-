-- =====================================================
-- LumbarMRI Database Schema
-- =====================================================
-- Description: Creates the database schema for storing
--              MRI imaging data and clinical notes
-- Author: Database Management Systems Course
-- Date: November 2025
-- =====================================================

USE LumbarMRI;
GO

-- =====================================================
-- Drop existing tables (for clean reinstall)
-- =====================================================
IF EXISTS (SELECT * FROM sysobjects WHERE name='Images' AND xtype='U')
    DROP TABLE Images;
IF EXISTS (SELECT * FROM sysobjects WHERE name='Series' AND xtype='U')
    DROP TABLE Series;
IF EXISTS (SELECT * FROM sysobjects WHERE name='Studies' AND xtype='U')
    DROP TABLE Studies;
IF EXISTS (SELECT * FROM sysobjects WHERE name='RadiologistsData' AND xtype='U')
    DROP TABLE RadiologistsData;
IF EXISTS (SELECT * FROM sysobjects WHERE name='Patients' AND xtype='U')
    DROP TABLE Patients;
GO

-- =====================================================
-- Table: Patients
-- =====================================================
-- Description: Stores patient identifiers
-- Primary Key: PatientID (matches folder naming convention)
-- =====================================================
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY
);
GO

-- =====================================================
-- Table: Studies
-- =====================================================
-- Description: MRI study sessions with metadata
-- Primary Key: StudyID (auto-generated)
-- Foreign Key: PatientID -> Patients
-- =====================================================
CREATE TABLE Studies (
    StudyID INT IDENTITY PRIMARY KEY,
    PatientID INT NOT NULL,
    StudyName NVARCHAR(255),
    StudyDate DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO

-- =====================================================
-- Table: Series
-- =====================================================
-- Description: Image series with orientation classification
-- Primary Key: SeriesID (auto-generated)
-- Foreign Key: StudyID -> Studies
-- =====================================================
CREATE TABLE Series (
    SeriesID INT IDENTITY PRIMARY KEY,
    StudyID INT NOT NULL,
    SeriesName NVARCHAR(255),
    Orientation NVARCHAR(50),
    FileCount INT,
    FOREIGN KEY (StudyID) REFERENCES Studies(StudyID)
);
GO

-- =====================================================
-- Table: Images
-- =====================================================
-- Description: Individual MRI image file references
-- Primary Key: ImageID (auto-generated)
-- Foreign Key: SeriesID -> Series
-- =====================================================
CREATE TABLE Images (
    ImageID INT IDENTITY PRIMARY KEY,
    SeriesID INT NOT NULL,
    FileName NVARCHAR(255),
    FilePath NVARCHAR(1024),
    FOREIGN KEY (SeriesID) REFERENCES Series(SeriesID)
);
GO

-- =====================================================
-- Table: RadiologistsData
-- =====================================================
-- Description: Clinical notes and radiologist assessments
-- Primary Key: RecordID (auto-generated)
-- Foreign Key: PatientID -> Patients
-- =====================================================
CREATE TABLE RadiologistsData (
    RecordID INT IDENTITY PRIMARY KEY,
    PatientID INT NOT NULL,
    Note NVARCHAR(MAX) NULL,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);
GO

-- =====================================================
-- Verify schema creation
-- =====================================================
PRINT 'Schema created successfully!';
PRINT '';
PRINT 'Tables created:';
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO
