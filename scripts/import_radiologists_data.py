import pyodbc
import pandas as pd

# =========================
# CONFIGURATION
# =========================
CSV_FILE = r"D:\HK251\Database Management Systems (CO3021)\Dataset\RadiologistsData.csv"
SQL_SERVER = "."
DATABASE = "LumbarMRI"

# =========================
# SQL SERVER CONNECTION
# =========================
conn = pyodbc.connect(
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SQL_SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)
cursor = conn.cursor()

# =========================
# CREATE TABLE IF NOT EXISTS
# =========================
print("Creating RadiologistsData table...")
cursor.execute("""
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RadiologistsData' AND xtype='U')
CREATE TABLE RadiologistsData (
    RecordID INT IDENTITY PRIMARY KEY,
    PatientID INT NOT NULL,
    Note NVARCHAR(MAX) NULL,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
)
""")
conn.commit()
print("Table created successfully!")

# =========================
# READ CSV FILE
# =========================
print(f"\nReading CSV file: {CSV_FILE}")
df = pd.read_csv(CSV_FILE)
print(f"Found {len(df)} records in CSV")

# Display column names
print(f"Columns: {list(df.columns)}")

# =========================
# IMPORT DATA
# =========================
success_count = 0
skipped_count = 0
created_patients = 0

for index, row in df.iterrows():
    patient_id = int(row['Patient ID'])
    note = row['Clinician\'s Notes'] if pd.notna(row['Clinician\'s Notes']) else None
    
    # Check if patient exists, if not create it
    cursor.execute("SELECT 1 FROM Patients WHERE PatientID=?", (patient_id,))
    if not cursor.fetchone():
        print(f"  Creating new Patient: {patient_id}")
        cursor.execute("INSERT INTO Patients (PatientID) VALUES (?)", (patient_id,))
        created_patients += 1
    
    # Insert radiologist note
    try:
        cursor.execute("""
            INSERT INTO RadiologistsData (PatientID, Note)
            VALUES (?, ?)
        """, (patient_id, note))
        success_count += 1
        
        if (success_count % 50 == 0):
            print(f"  Imported {success_count} records...")
            
    except Exception as e:
        print(f"  Error importing Patient {patient_id}: {e}")
        skipped_count += 1
        continue

conn.commit()
conn.close()

# =========================
# SUMMARY
# =========================
print("\n" + "="*50)
print("IMPORT COMPLETED!")
print("="*50)
print(f"Total records in CSV: {len(df)}")
print(f"Successfully imported: {success_count}")
print(f"New patients created: {created_patients}")
print(f"Skipped (errors): {skipped_count}")
print("="*50)
