import pyodbc

# =========================
# SQL SERVER CONNECTION
# =========================
conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER=.;"
    f"DATABASE=LumbarMRI;"
    f"Trusted_Connection=yes;"
)
cursor = conn.cursor()

print("="*70)
print("DATABASE STATISTICS - LumbarMRI")
print("="*70)

# 1. Count total records in each table
print("\n📊 RECORD COUNTS:")
print("-"*70)

cursor.execute("SELECT COUNT(*) FROM Patients")
patient_count = cursor.fetchone()[0]
print(f"Patients:         {patient_count:>6} records")

cursor.execute("SELECT COUNT(*) FROM Studies")
study_count = cursor.fetchone()[0]
print(f"Studies:          {study_count:>6} records")

cursor.execute("SELECT COUNT(*) FROM Series")
series_count = cursor.fetchone()[0]
print(f"Series:           {series_count:>6} records")

cursor.execute("SELECT COUNT(*) FROM Images")
image_count = cursor.fetchone()[0]
print(f"Images:           {image_count:>6} records")

cursor.execute("SELECT COUNT(*) FROM RadiologistsData")
radio_count = cursor.fetchone()[0]
print(f"RadiologistsData: {radio_count:>6} records")

# 2. Check for patients without notes
print("\n\n🔍 DATA INTEGRITY CHECKS:")
print("-"*70)

cursor.execute("""
    SELECT COUNT(*) 
    FROM Patients p
    LEFT JOIN RadiologistsData r ON p.PatientID = r.PatientID
    WHERE r.RecordID IS NULL
""")
no_notes = cursor.fetchone()[0]
print(f"Patients without notes: {no_notes}")

cursor.execute("""
    SELECT COUNT(*) 
    FROM Patients p
    LEFT JOIN Studies s ON p.PatientID = s.PatientID
    WHERE s.StudyID IS NULL
""")
no_studies = cursor.fetchone()[0]
print(f"Patients without MRI studies: {no_studies}")

# 3. Orientation distribution
print("\n\n📐 SERIES ORIENTATION DISTRIBUTION:")
print("-"*70)

cursor.execute("""
    SELECT Orientation, COUNT(*) as Count
    FROM Series
    GROUP BY Orientation
    ORDER BY Count DESC
""")
for row in cursor.fetchall():
    print(f"{row.Orientation:15s}: {row.Count:>5} series")

# 4. Sample data - Patient with note and studies
print("\n\n📋 SAMPLE DATA - Patient 1:")
print("-"*70)

cursor.execute("""
    SELECT p.PatientID, r.Note
    FROM Patients p
    LEFT JOIN RadiologistsData r ON p.PatientID = r.PatientID
    WHERE p.PatientID = 1
""")
row = cursor.fetchone()
if row:
    print(f"Patient ID: {row.PatientID}")
    print(f"Radiologist Note: {row.Note[:150] if row.Note else 'No note'}...")

cursor.execute("""
    SELECT StudyName, StudyDate
    FROM Studies
    WHERE PatientID = 1
""")
print("\nStudies:")
for row in cursor.fetchall():
    print(f"  - {row.StudyName} ({row.StudyDate})")

cursor.execute("""
    SELECT s.SeriesName, s.Orientation, s.FileCount
    FROM Series s
    JOIN Studies st ON s.StudyID = st.StudyID
    WHERE st.PatientID = 1
""")
print("\nSeries:")
for row in cursor.fetchall():
    print(f"  - {row.SeriesName:40s} | {row.Orientation:12s} | {row.FileCount} files")

# 5. Top patients with most images
print("\n\n🏆 TOP 5 PATIENTS WITH MOST IMAGES:")
print("-"*70)

cursor.execute("""
    SELECT TOP 5 
        p.PatientID,
        COUNT(DISTINCT st.StudyID) as Studies,
        COUNT(DISTINCT s.SeriesID) as Series,
        COUNT(i.ImageID) as Images
    FROM Patients p
    JOIN Studies st ON p.PatientID = st.PatientID
    JOIN Series s ON st.StudyID = s.StudyID
    JOIN Images i ON s.SeriesID = i.SeriesID
    GROUP BY p.PatientID
    ORDER BY Images DESC
""")
print(f"{'Patient ID':<12} {'Studies':<10} {'Series':<10} {'Images':<10}")
print("-"*70)
for row in cursor.fetchall():
    print(f"{row.PatientID:<12} {row.Studies:<10} {row.Series:<10} {row.Images:<10}")

# 6. Check for NULL notes
print("\n\n📝 NOTES STATUS:")
print("-"*70)

cursor.execute("""
    SELECT 
        COUNT(*) as Total,
        SUM(CASE WHEN Note IS NOT NULL THEN 1 ELSE 0 END) as HasNote,
        SUM(CASE WHEN Note IS NULL THEN 1 ELSE 0 END) as NullNote
    FROM RadiologistsData
""")
row = cursor.fetchone()
print(f"Total records: {row.Total}")
print(f"With notes:    {row.HasNote}")
print(f"NULL notes:    {row.NullNote}")

print("\n" + "="*70)
print("✅ DATA CHECK COMPLETED!")
print("="*70)

conn.close()
