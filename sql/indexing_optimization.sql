/******************************************************************************
-- SQL SCRIPT FOR: Assignment 2 - Database Management Systems (CO3021)
-- PROJECT: LumbarMRI Database Optimization
-- AUTHOR: Pham Quang Tien Thanh (and Team Members)
-- GITHUB: https://github.com/Thanhizme/Database-Management-Systems-CO3021-.git
--
-- DESCRIPTION:
-- This script contains T-SQL queries for performance optimization case studies
-- demonstrating indexing strategies and query optimization techniques.
--
-- USAGE INSTRUCTIONS:
-- 1. Execute each Case Study section sequentially
-- 2. Enable "Include Actual Execution Plan" (Ctrl+M) in SSMS before running
-- 3. Run the "BEFORE" query and record execution plan metrics
-- 4. Execute the "OPTIMIZATION" script to create indexes
-- 5. Run the "AFTER" query and compare performance improvements
-- 6. Execute "CLEANUP" script before proceeding to the next case study
--
-- NOTE: Performance metrics may vary based on hardware and SQL Server version
******************************************************************************/

USE LumbarMRI;
GO

-- Enable I/O and Time statistics for all queries in this session
SET STATISTICS IO, TIME ON;
GO

-- ============================================================================
-- CASE STUDY 1: Optimizing Highly Selective WHERE Clause (Scan vs. Seek)
-- Reference: Section 4.1 of the Assignment Report
-- ============================================================================

/*
OBJECTIVE: Demonstrate the performance improvement when adding a non-clustered
index on a highly selective column used in WHERE clause filters.

SCENARIO: Query filtering by 'Orientation' column without an index results in
a full table scan. Adding an index enables efficient index seek operations.
*/

-- 1. BEFORE OPTIMIZATION (Baseline Performance)
-- Expected Result: Clustered Index Scan, Logical Reads: ~42
PRINT '========================================';
PRINT 'CASE STUDY 1: BEFORE OPTIMIZATION';
PRINT '========================================';

SELECT * 
FROM Series 
WHERE Orientation = 'Box';
GO


-- 2. OPTIMIZATION: Create Non-Clustered Index
PRINT '';
PRINT 'Creating non-clustered index on Orientation column...';

CREATE NONCLUSTERED INDEX IX_Series_Orientation
ON Series(Orientation);
GO


-- 3. AFTER OPTIMIZATION (Optimized Performance)
-- Expected Result: Index Seek + Key Lookup (~85% cost), Logical Reads: ~9
PRINT '';
PRINT '========================================';
PRINT 'CASE STUDY 1: AFTER OPTIMIZATION';
PRINT '========================================';

SELECT * 
FROM Series 
WHERE Orientation = 'Box';
GO


-- 4. CLEANUP: Remove Index for Next Case Study
PRINT '';
PRINT 'Cleaning up Case Study 1 indexes...';

DROP INDEX IF EXISTS IX_Series_Orientation ON Series;
GO

PRINT 'Case Study 1 completed successfully.';
PRINT '';
PRINT '';


-- ============================================================================
-- CASE STUDY 2: Optimizing Multi-Table JOINs with Foreign Key Indexes
-- Reference: Section 4.2 of the Assignment Report
-- ============================================================================

/*
OBJECTIVE: Demonstrate performance improvement when adding indexes on foreign
key columns used in JOIN operations.

SCENARIO: JOIN query without foreign key indexes results in hash match joins
with table scans. Adding indexes enables efficient nested loop joins with seeks.
*/

-- 1. BEFORE OPTIMIZATION (Baseline Performance)
-- Expected Result: 2x Clustered Index Scan + Hash Match (~48% cost)
--                  Total Logical Reads: ~52
PRINT '========================================';
PRINT 'CASE STUDY 2: BEFORE OPTIMIZATION';
PRINT '========================================';

SELECT
    s.SeriesID, 
    s.SeriesName, 
    s.Orientation
FROM Studies AS st
INNER JOIN Series AS s ON st.StudyID = s.StudyID
WHERE st.PatientID = 100;
GO


-- 2. OPTIMIZATION: Create Indexes on Foreign Key Columns
PRINT '';
PRINT 'Creating foreign key indexes...';

CREATE NONCLUSTERED INDEX IX_Studies_PatientID 
ON Studies(PatientID);

CREATE NONCLUSTERED INDEX IX_Series_StudyID 
ON Series(StudyID);
GO


-- 3. AFTER OPTIMIZATION (Optimized Performance)
-- Expected Result: 2x Index Seek + Nested Loops + Key Lookup (~73% cost)
--                  Total Logical Reads: ~16
PRINT '';
PRINT '========================================';
PRINT 'CASE STUDY 2: AFTER OPTIMIZATION';
PRINT '========================================';

SELECT
    s.SeriesID, 
    s.SeriesName, 
    s.Orientation
FROM Studies AS st
INNER JOIN Series AS s ON st.StudyID = s.StudyID
WHERE st.PatientID = 100;
GO


-- 4. CLEANUP: Remove Indexes for Next Case Study
PRINT '';
PRINT 'Cleaning up Case Study 2 indexes...';

DROP INDEX IF EXISTS IX_Studies_PatientID ON Studies;
DROP INDEX IF EXISTS IX_Series_StudyID ON Series;
GO

PRINT 'Case Study 2 completed successfully.';
PRINT '';
PRINT '';


-- ============================================================================
-- CASE STUDY 3: Eliminating Key Lookups with Covering Indexes
-- Reference: Section 4.3 of the Assignment Report
-- ============================================================================

/*
OBJECTIVE: Demonstrate how covering indexes eliminate expensive key lookup
operations by including all required columns in the index.

SCENARIO: Query with index seeks still incurs key lookups (73% cost) to retrieve
non-indexed columns. A covering index with INCLUDE clause eliminates key lookups.
*/

-- 1. SETUP: Recreate Case Study 2 Final State
PRINT '========================================';
PRINT 'CASE STUDY 3: SETUP (Recreating CS2 State)';
PRINT '========================================';

CREATE NONCLUSTERED INDEX IX_Studies_PatientID 
ON Studies(PatientID);

CREATE NONCLUSTERED INDEX IX_Series_StudyID 
ON Series(StudyID);
GO


-- BEFORE OPTIMIZATION (Starting from Case Study 2 "After" state)
-- Expected Result: Key Lookup operation with ~73% cost
--                  Total Logical Reads: ~16
PRINT '';
PRINT '========================================';
PRINT 'CASE STUDY 3: BEFORE OPTIMIZATION';
PRINT '========================================';

SELECT
    s.SeriesID, 
    s.SeriesName, 
    s.Orientation
FROM Studies AS st
INNER JOIN Series AS s ON st.StudyID = s.StudyID
WHERE st.PatientID = 100;
GO


-- 2. OPTIMIZATION: Replace Index with Covering Index
PRINT '';
PRINT 'Creating covering index with INCLUDE clause...';

DROP INDEX IF EXISTS IX_Series_StudyID ON Series;

CREATE NONCLUSTERED INDEX IX_Series_StudyID_Covering
ON Series(StudyID)                                    -- Key column for JOIN
INCLUDE (SeriesID, SeriesName, Orientation);          -- Covered columns for SELECT
GO


-- 3. AFTER OPTIMIZATION (Optimized Performance)
-- Expected Result: NO KEY LOOKUP operation
--                  Total Logical Reads: ~4 (75% reduction)
PRINT '';
PRINT '========================================';
PRINT 'CASE STUDY 3: AFTER OPTIMIZATION';
PRINT '========================================';

SELECT
    s.SeriesID, 
    s.SeriesName, 
    s.Orientation
FROM Studies AS st
INNER JOIN Series AS s ON st.StudyID = s.StudyID
WHERE st.PatientID = 100;
GO


-- 4. FINAL CLEANUP: Remove All Indexes
PRINT '';
PRINT 'Performing final cleanup...';

DROP INDEX IF EXISTS IX_Studies_PatientID ON Studies;
DROP INDEX IF EXISTS IX_Series_StudyID_Covering ON Series;
GO

PRINT 'Case Study 3 completed successfully.';
PRINT '';
PRINT '';


-- ============================================================================
-- SUMMARY AND PERFORMANCE COMPARISON
-- ============================================================================

PRINT '========================================';
PRINT 'ALL CASE STUDIES COMPLETED';
PRINT '========================================';
PRINT '';
PRINT 'PERFORMANCE SUMMARY:';
PRINT '--------------------';
PRINT 'Case Study 1: Scan → Seek';
PRINT '  Logical Reads: 42 → 9 (78.6% reduction)';
PRINT '';
PRINT 'Case Study 2: Hash Match → Nested Loops';
PRINT '  Logical Reads: 52 → 16 (69.2% reduction)';
PRINT '';
PRINT 'Case Study 3: With Key Lookup → Covering Index';
PRINT '  Logical Reads: 16 → 4 (75.0% reduction)';
PRINT '';
PRINT 'Overall Optimization: 52 → 4 (92.3% reduction)';
PRINT '========================================';
GO

-- Disable statistics
SET STATISTICS IO, TIME OFF;
GO
