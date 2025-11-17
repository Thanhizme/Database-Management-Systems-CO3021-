USE LumbarMRI;
GO

-- ============================================================================
-- PART 1: BASIC CONCEPTS - ACID Properties
-- ============================================================================

/*
SQL Server guarantees the ACID properties:
- Atomicity: All or nothing
- Consistency: Valid state before/after
- Isolation: Transactions are isolated
- Durability: Changes are permanent
*/

-- ══════════════════════════════════════════════════════════════════════════
-- EXAMPLE 1: Simple Transaction - COMMIT vs ROLLBACK
-- ══════════════════════════════════════════════════════════════════════════

BEGIN TRANSACTION;

-- Add a patient and an associated study
INSERT INTO Patients (PatientID) VALUES (600);
INSERT INTO Studies (PatientID, StudyName, StudyDate) 
VALUES (600, 'Lumbar MRI', GETDATE());

-- Check current state (not yet committed)
SELECT * FROM Patients WHERE PatientID = 600;
SELECT * FROM Studies WHERE PatientID = 600;

-- Decide whether to validate or cancel
-- COMMIT TRANSACTION;  -- Validates all modifications
ROLLBACK TRANSACTION;   -- Cancels all modifications

-- Verification
SELECT * FROM Patients WHERE PatientID = 600;
SELECT * FROM Studies WHERE PatientID = 600;


-- ══════════════════════════════════════════════════════════════════════════
-- EXAMPLE 2: Transaction with TRY-CATCH (Error Handling)
-- SQL SERVER SPECIFIC
-- ══════════════════════════════════════════════════════════════════════════

BEGIN TRY
    BEGIN TRANSACTION;

    -- Attempt insertion with possible violation (existing primary key)
    INSERT INTO Patients (PatientID) VALUES (1);  -- assumed to already exist
    INSERT INTO Studies (PatientID, StudyName, StudyDate) 
    VALUES (1, 'Follow-up MRI', GETDATE());

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    PRINT 'Error detected: ' + ERROR_MESSAGE();
    ROLLBACK TRANSACTION;
END CATCH;


-- ============================================================================
-- PART 2: ISOLATION LEVELS
-- ============================================================================

-- ══════════════════════════════════════════════════════════════════════════
-- EXAMPLE 3: "Dirty Read" Problem and Solution
-- ══════════════════════════════════════════════════════════════════════════

-- SESSION 1 (modifying transaction)
BEGIN TRANSACTION;

UPDATE Studies 
SET StudyName = 'Updated MRI' 
WHERE StudyID = 566;

-- Wait for 10 seconds to simulate a long-running transaction
WAITFOR DELAY '00:00:10';

-- Roll back the modification after the delay
ROLLBACK TRANSACTION;

-- SESSION 2 (reading transaction)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;

-- Non-blocking read that may see uncommitted changes from Session 1
SELECT * FROM Studies WHERE StudyID = 566; 

ROLLBACK TRANSACTION;





-- Switch to master to run ALTER DATABASE
USE master;
GO

-- ============================
-- Step 0: Enable READ_COMMITTED_SNAPSHOT (statement-level snapshot)
-- We do it on DoctorNotes because LumbarMRI is too big (takes more than 20mins)
-- With DoctorNotes just 20s
-- ============================
ALTER DATABASE DoctorNotes SET READ_COMMITTED_SNAPSHOT ON;
GO

-- SESSION 1: Modifying transaction
USE DoctorNotes;
GO
BEGIN TRANSACTION;

-- Modify a row in ClinicalNotes
UPDATE dbo.ClinicalNotes
SET CliniciansNote = 'Updated note'
WHERE NoteID = 1;  -- choose an existing NoteID

-- Wait for 10 seconds to simulate a long-running transaction
WAITFOR DELAY '00:00:10';

-- Rollback the modification after the delay
ROLLBACK TRANSACTION;


-- SESSION 2: Reading transaction
-- Uses READ COMMITTED (statement-level snapshot)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

-- Read the row without being blocked by Session 1
SELECT * FROM dbo.ClinicalNotes WHERE NoteID = 1;

COMMIT TRANSACTION;
GO


-- ============================================================================
-- Demonstrates how READ_COMMITTED_SNAPSHOT (RCS) can return different versions
-- for successive SELECTs in the same transaction
-- ============================================================================

-- SESSION 1: Modifying transaction
BEGIN TRANSACTION;

UPDATE dbo.ClinicalNotes
SET CliniciansNote = 'Updated note by Session 1'
WHERE NoteID = 1;

-- Simulate a short delay to overlap with Session 2
WAITFOR DELAY '00:00:5';

-- Commit the modification to make it visible to other transactions
COMMIT TRANSACTION;


-- SESSION 2: Reading transaction under RCS
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

-- First SELECT
SELECT * FROM dbo.ClinicalNotes WHERE NoteID = 1;
-- → Sees the original version

-- Wait a few seconds, during which Session 1 commits
WAITFOR DELAY '00:00:6';

-- Second SELECT
SELECT * FROM dbo.ClinicalNotes WHERE NoteID = 1;
-- → May see the new committed version
COMMIT TRANSACTION;


-- ══════════════════════════════════════════════════════════════════════════
-- EXAMPLE 4: SNAPSHOT Isolation (SQL SERVER SPECIFIC)
-- ══════════════════════════════════════════════════════════════════════════
-- Switch to master to run ALTER DATABASE
USE master;
GO

-- Enable SNAPSHOT isolation for the database
ALTER DATABASE DoctorNotes SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE DoctorNotes SET READ_COMMITTED_SNAPSHOT ON;

USE DoctorNotes;  
GO

-- SESSION 1: Modifying transaction
BEGIN TRANSACTION;

UPDATE dbo.ClinicalNotes
SET CliniciansNote = 'Completely new note'
WHERE NoteID = 1;

-- Simulate a short delay to overlap with Session 2
WAITFOR DELAY '00:00:5';

-- Commit the modification to make it visible to other transactions
COMMIT TRANSACTION;




-- SESSION 2: Reading transaction under READ_COMMITTED_SNAPSHOT
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

-- First SELECT: sees the last committed version at the start
SELECT * FROM dbo.ClinicalNotes WHERE NoteID = 1;
-- → Sees the original version if Session 1 hasn't committed yet

-- Wait a few seconds, during which Session 1 commits
WAITFOR DELAY '00:00:6';

-- Still sees the original version
SELECT * FROM dbo.ClinicalNotes WHERE NoteID = 1;

COMMIT TRANSACTION;
GO


-- ============================================================================
--  Monitoring Active Transactions in SQL Server using DMVs
-- ============================================================================

USE DoctorNotes;
GO

-- SESSION 1: Start a long-running transaction
BEGIN TRANSACTION;

-- Modify a row to create an active transaction
UPDATE dbo.ClinicalNotes
SET CliniciansNote = 'Monitoring transaction example'
WHERE NoteID = 1;

-- Simulate a delay to keep the transaction open
WAITFOR DELAY '00:00:30';  -- 30 seconds
-- Do NOT commit yet, so the transaction remains active




-- SESSION 2: Query DMVs to monitor active transactions
SELECT
    at.transaction_id,
    at.name AS transaction_name,
    at.transaction_state,
    at.transaction_type,
    s.session_id,
    s.host_name,
    s.login_name,
    r.status AS request_status,
    r.command
FROM sys.dm_tran_active_transactions at
JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id;
