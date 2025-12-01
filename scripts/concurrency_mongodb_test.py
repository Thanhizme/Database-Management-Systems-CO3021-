import threading
import time
from pymongo import MongoClient
from pymongo.errors import PyMongoError
from datetime import datetime

def log(msg):
	print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}")

def update_session(session_name, delay=5):
	client = MongoClient("mongodb://localhost:27017/?replicaSet=rs0")
	db = client["mri_db"]
	coll = db["mri_images"]
	with client.start_session() as session:
		while True:  # retry loop
			try:
				with session.start_transaction():
					log(f"{session_name} - Transaction Started.")
					result = coll.update_one(
						{"patientID": "01_MRI_Data"},
						{"$set": {"description": f"Updated by {session_name}"}},
						session=session
					)
					log(f"{session_name} - Update command sent. Matched={result.matched_count}")
					if delay > 0:
						log(f"{session_name} - Holding before commit for {delay}s...")
						time.sleep(delay)
					log(f"{session_name} - Committing transaction...")
					session.commit_transaction()
					log(f"{session_name} - Commit complete.")
				break
			except PyMongoError as e:
				if hasattr(e, 'details') and e.details and 'errorLabels' in e.details:
					if 'TransientTransactionError' in e.details['errorLabels']:
						log(f"{session_name} - WriteConflict / TransientTransactionError detected, retrying...")
						time.sleep(1)
						continue
				log(f"{session_name} - ERROR: {e}")
				break

t1 = threading.Thread(target=update_session, args=("Session 1", 5))
t2 = threading.Thread(target=update_session, args=("Session 2", 5))
t1.start()
time.sleep(1)
t2.start()
t1.join()
t2.join()
