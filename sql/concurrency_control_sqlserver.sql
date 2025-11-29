/*
 * CONCURRENCY CONTROL - ALL CASE STUDIES
 * ======================================
 * Includes case studies for Blocking and Deadlock
 *
 * 1. CASE STUDY 1: BLOCKING
 *    - SESSION 1: Transaction holds Exclusive Lock (X Lock)
 *    - SESSION 2: Transaction wants to read data (Shared Lock)
 *
 * 2. CASE STUDY 2: DEADLOCK SIMULATION
 *    - SESSION 1: Transaction A
 *    - SESSION 2: Transaction B
 */

-- ===============================
-- CASE STUDY 1: BLOCKING
-- ===============================
-- SESSION 1
USE LumbarMRI;
GO
PRINT '========================================';
PRINT 'SESSION 1: Start update transaction';
PRINT '========================================';
PRINT '';
BEGIN TRANSACTION;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Updating patient with PatientID = 1...';
    UPDATE Studies
    SET StudyName = 'Blocking Test - Session 1'
    WHERE StudyID = 1;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Acquired EXCLUSIVE LOCK on StudyID = 1';
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Holding lock for 15 seconds so SESSION 2 will be blocked...';
    PRINT '';
    PRINT '>>> NOW RUN SESSION 2 IMMEDIATELY <<<';
    WAITFOR DELAY '00:00:15';
COMMIT;
GO

-- SESSION 2
USE LumbarMRI;
GO
PRINT '========================================';
PRINT 'SESSION 2: Try to read data';
PRINT '========================================';
PRINT '';
PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Requesting SHARED LOCK to read StudyID = 1...';
PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Waiting... (BLOCKED)';
PRINT '';
SELECT 
    StudyID,
    PatientID,
    StudyName,
    StudyDate
FROM Studies 
WHERE StudyID = 1;
PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Acquired SHARED LOCK and read successfully!';
GO

-- ===============================
-- CASE STUDY 2: DEADLOCK SIMULATION
-- ===============================
-- SESSION 1 (Transaction A)
USE LumbarMRI;
GO
PRINT '================================================================';
PRINT 'SESSION 1 (Transaction A): Start';
PRINT '================================================================';
PRINT '';
SET DEADLOCK_PRIORITY LOW;
BEGIN TRANSACTION;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Step 1 - Acquire X Lock on Studies (StudyID=1)';
    UPDATE Studies SET StudyName = 'Deadlock Test - Session 1' WHERE StudyID = 1;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Acquired X Lock on Studies';
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Wait for 7 seconds...';
    WAITFOR DELAY '00:00:07';
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 1: Step 2 - Try to acquire X Lock on Series (SeriesID=1)';
    UPDATE Series SET SeriesName = 'Session A - Step 2' WHERE SeriesID = 1;
COMMIT;
GO

-- SESSION 2 (Transaction B)
USE LumbarMRI;
GO
PRINT '================================================================';
PRINT 'SESSION 2 (Transaction B): Start';
PRINT '================================================================';
PRINT '';
SET DEADLOCK_PRIORITY HIGH;
BEGIN TRANSACTION;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Step 1 - Acquire X Lock on Series (SeriesID=1)';
    UPDATE Series SET SeriesName = 'Session B - Step 1' WHERE SeriesID = 1;
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Acquired X Lock on Series';
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Wait for 7 seconds...';
    WAITFOR DELAY '00:00:07';
    PRINT '[' + CONVERT(VARCHAR, GETDATE(), 108) + '] SESSION 2: Step 2 - Try to acquire X Lock on Studies (StudyID=1)';
    UPDATE Studies SET StudyName = 'Session B - Step 2' WHERE StudyID = 1;
COMMIT;
GO
