-- =====================================================
-- LumbarMRI Database - Sample Queries
-- =====================================================

USE LumbarMRI;
GO

-- =====================================================
-- 1. BASIC QUERIES
-- =====================================================

-- Count records in each table
SELECT 'Patients' as TableName, COUNT(*) as RecordCount FROM Patients
UNION ALL
SELECT 'Studies', COUNT(*) FROM Studies
UNION ALL
SELECT 'Series', COUNT(*) FROM Series
UNION ALL
SELECT 'Images', COUNT(*) FROM Images
UNION ALL
SELECT 'RadiologistsData', COUNT(*) FROM RadiologistsData;
GO

-- =====================================================
-- 2. PATIENT QUERIES
-- =====================================================

-- Get all information for a specific patient
DECLARE @PatientID INT = 1;

SELECT 
    p.PatientID,
    r.Note as ClinicalNote,
    COUNT(DISTINCT s.StudyID) as TotalStudies,
    COUNT(DISTINCT se.SeriesID) as TotalSeries,
    COUNT(i.ImageID) as TotalImages
FROM Patients p
LEFT JOIN RadiologistsData r ON p.PatientID = r.PatientID
LEFT JOIN Studies s ON p.PatientID = s.PatientID
LEFT JOIN Series se ON s.StudyID = se.StudyID
LEFT JOIN Images i ON se.SeriesID = i.SeriesID
WHERE p.PatientID = @PatientID
GROUP BY p.PatientID, r.Note;
GO

-- =====================================================
-- 3. STUDY QUERIES
-- =====================================================

-- Find studies within date range
SELECT 
    s.StudyID,
    s.PatientID,
    s.StudyName,
    s.StudyDate,
    COUNT(se.SeriesID) as SeriesCount
FROM Studies s
LEFT JOIN Series se ON s.StudyID = se.StudyID
WHERE s.StudyDate BETWEEN '2016-01-01' AND '2016-12-31'
GROUP BY s.StudyID, s.PatientID, s.StudyName, s.StudyDate
ORDER BY s.StudyDate DESC;
GO

-- =====================================================
-- 4. SERIES QUERIES
-- =====================================================

-- Series orientation distribution
SELECT 
    Orientation,
    COUNT(*) as Count,
    AVG(FileCount) as AvgFiles,
    MIN(FileCount) as MinFiles,
    MAX(FileCount) as MaxFiles
FROM Series
GROUP BY Orientation
ORDER BY Count DESC;
GO

-- Find all Sagittal series
SELECT 
    s.StudyID,
    st.PatientID,
    s.SeriesName,
    s.FileCount
FROM Series s
JOIN Studies st ON s.StudyID = st.StudyID
WHERE s.Orientation = 'Sagittal'
ORDER BY s.FileCount DESC;
GO

-- =====================================================
-- 5. IMAGE QUERIES
-- =====================================================

-- Get image file paths for a specific series
SELECT TOP 10
    i.FileName,
    i.FilePath
FROM Images i
JOIN Series s ON i.SeriesID = s.SeriesID
WHERE s.SeriesName LIKE '%T2_TSE_SAG%'
ORDER BY i.FileName;
GO

-- =====================================================
-- 6. CLINICAL DATA QUERIES
-- =====================================================

-- Patients with notes containing specific keywords
SELECT 
    p.PatientID,
    LEFT(r.Note, 200) as NotePreview
FROM Patients p
JOIN RadiologistsData r ON p.PatientID = r.PatientID
WHERE r.Note LIKE '%disc herniation%'
   OR r.Note LIKE '%compression%';
GO

-- Patients without clinical notes
SELECT p.PatientID
FROM Patients p
LEFT JOIN RadiologistsData r ON p.PatientID = r.PatientID
WHERE r.Note IS NULL;
GO

-- =====================================================
-- 7. DATA QUALITY CHECKS
-- =====================================================

-- Patients without MRI studies
SELECT p.PatientID
FROM Patients p
LEFT JOIN Studies s ON p.PatientID = s.PatientID
WHERE s.StudyID IS NULL;
GO

-- Studies without series
SELECT s.StudyID, s.PatientID, s.StudyName
FROM Studies s
LEFT JOIN Series se ON s.StudyID = se.StudyID
WHERE se.SeriesID IS NULL;
GO

-- Series with mismatched file counts
SELECT 
    s.SeriesID,
    s.SeriesName,
    s.FileCount as ReportedCount,
    COUNT(i.ImageID) as ActualCount
FROM Series s
LEFT JOIN Images i ON s.SeriesID = i.SeriesID
GROUP BY s.SeriesID, s.SeriesName, s.FileCount
HAVING s.FileCount <> COUNT(i.ImageID);
GO

-- =====================================================
-- 8. STATISTICAL QUERIES
-- =====================================================

-- Top 10 patients with most images
SELECT TOP 10
    p.PatientID,
    COUNT(DISTINCT st.StudyID) as Studies,
    COUNT(DISTINCT s.SeriesID) as Series,
    COUNT(i.ImageID) as TotalImages
FROM Patients p
JOIN Studies st ON p.PatientID = st.PatientID
JOIN Series s ON st.StudyID = s.StudyID
JOIN Images i ON s.SeriesID = i.SeriesID
GROUP BY p.PatientID
ORDER BY TotalImages DESC;
GO

-- Monthly study distribution
SELECT 
    YEAR(StudyDate) as Year,
    MONTH(StudyDate) as Month,
    COUNT(*) as StudyCount
FROM Studies
WHERE StudyDate IS NOT NULL
GROUP BY YEAR(StudyDate), MONTH(StudyDate)
ORDER BY Year, Month;
GO
