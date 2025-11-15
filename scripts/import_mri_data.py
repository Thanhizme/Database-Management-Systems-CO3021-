import pyodbc
import os
import re
from datetime import datetime

# =========================
# CONFIGURATION
# =========================
ROOT_DIR = r"D:\HK251\Database Management Systems (CO3021)\Dataset\MRI_Data\01_MRI_Data"  # Path to the folder containing 0001, 0002, ...
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
# CREATE TABLES IF THEY DON'T EXIST
# =========================
cursor.execute("""
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Patients' AND xtype='U')
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY
)
""")
cursor.execute("""
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Studies' AND xtype='U')
CREATE TABLE Studies (
    StudyID INT IDENTITY PRIMARY KEY,
    PatientID INT,
    StudyName NVARCHAR(255),
    StudyDate DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
)
""")
cursor.execute("""
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Series' AND xtype='U')
CREATE TABLE Series (
    SeriesID INT IDENTITY PRIMARY KEY,
    StudyID INT,
    SeriesName NVARCHAR(255),
    Orientation NVARCHAR(50),
    FileCount INT,
    FOREIGN KEY (StudyID) REFERENCES Studies(StudyID)
)
""")
cursor.execute("""
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Images' AND xtype='U')
CREATE TABLE Images (
    ImageID INT IDENTITY PRIMARY KEY,
    SeriesID INT,
    FileName NVARCHAR(255),
    FilePath NVARCHAR(1024),
    FOREIGN KEY (SeriesID) REFERENCES Series(SeriesID)
)
""")
conn.commit()

# =========================
# INSERT FUNCTIONS
# =========================
def insert_patient(patient_id):
    cursor.execute("""
        IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID=?)
        INSERT INTO Patients (PatientID) VALUES (?)
    """, (patient_id, patient_id))

def insert_study(patient_id, study_name):
    study_date = None
    match = re.search(r'(\d{8})_(\d{6})', study_name)
    if match:
        date_str = match.group(1) + match.group(2)
        try:
            study_date = datetime.strptime(date_str, "%Y%m%d%H%M%S")
        except:
            pass

    cursor.execute("""
        INSERT INTO Studies (PatientID, StudyName, StudyDate)
        OUTPUT INSERTED.StudyID
        VALUES (?, ?, ?)
    """, (patient_id, study_name, study_date))
    result = cursor.fetchone()
    if result is None:
        raise Exception(f"Failed to insert study: {study_name}")
    study_id = result[0]  # retrieve the ID directly
    return study_id


def insert_series(study_id, series_name, file_count):
    sname = series_name.upper()
    orientation = None

    # Orientation detection
    if 'SAG' in sname:
        orientation = 'Sagittal'
    elif 'TRA' in sname:
        orientation = 'Transverse'
    elif 'BOX' in sname:
        orientation = 'Box'
    elif 'C-SPINE' in sname or 'CSPINE' in sname or 'L-SPINE' in sname or 'LSPINE' in sname:
        orientation = 'Spine'
    else:
        orientation = 'Unknown'  # For anything that doesn't match a rule

    cursor.execute("""
        INSERT INTO Series (StudyID, SeriesName, Orientation, FileCount)
        OUTPUT INSERTED.SeriesID
        VALUES (?, ?, ?, ?)
    """, (study_id, series_name, orientation, file_count))
    result = cursor.fetchone()
    if result is None:
        raise Exception(f"Failed to insert series: {series_name}")
    series_id = result[0]
    return series_id



def insert_image(series_id, file_name, file_path):
    cursor.execute("""
        INSERT INTO Images (SeriesID, FileName, FilePath)
        VALUES (?, ?, ?)
    """, (series_id, file_name, file_path))

# =========================
# DIRECTORY TRAVERSAL
# =========================
for patient_folder in sorted(os.listdir(ROOT_DIR)):
    patient_path = os.path.join(ROOT_DIR, patient_folder)
    if not os.path.isdir(patient_path) or not patient_folder.isdigit():
        continue

    patient_id = int(patient_folder)
    print(f"Processing Patient {patient_id}")
    insert_patient(patient_id)
    conn.commit()  # commit patient

    for study_folder in os.listdir(patient_path):
        study_path = os.path.join(patient_path, study_folder)
        if not os.path.isdir(study_path):
            continue

        print(f"  Study: {study_folder}")
        study_id = insert_study(patient_id, study_folder)
        conn.commit()  # commit study

        for series_folder in os.listdir(study_path):
            series_path = os.path.join(study_path, series_folder)
            if not os.path.isdir(series_path):
                continue

            files = [f for f in os.listdir(series_path) if f.lower().endswith(".ima")]
            if not files:
                continue

            print(f"    Series: {series_folder}, {len(files)} files")
            series_id = insert_series(study_id, series_folder, len(files))

            for f in sorted(files):
                file_path = os.path.join(series_path, f)
                try:
                    insert_image(series_id, f, file_path)
                except Exception as e:
                    print(f"      File error {f}: {e}")
            conn.commit()  # commit per series

conn.close()
print("Import completed!")
