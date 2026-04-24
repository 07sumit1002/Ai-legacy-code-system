import schedule
import time
import shutil
import os
import datetime

VECTOR_STORE_DIR = "vector_stores"
UPLOADED_DATA_DIR = "uploaded_data"

def automatic_nightly_cleanup():
    print(f"[{datetime.datetime.now()}] Executing Midnight Codebase Purge...")
    try:
        if os.path.exists(VECTOR_STORE_DIR):
            shutil.rmtree(VECTOR_STORE_DIR, ignore_errors=True)
        if os.path.exists(UPLOADED_DATA_DIR):
            shutil.rmtree(UPLOADED_DATA_DIR, ignore_errors=True)
            
        os.makedirs(VECTOR_STORE_DIR, exist_ok=True)
        os.makedirs(UPLOADED_DATA_DIR, exist_ok=True)
        print(f"[{datetime.datetime.now()}] Codebases explicitly wiped successfully.")
    except Exception as e:
        print(f"[{datetime.datetime.now()}] Cleanup exception: {e}")

# Bind the scheduler to strictly trigger at 12:00 AM automatically
schedule.every().day.at("00:00").do(automatic_nightly_cleanup)

print(f"[{datetime.datetime.now()}] Nightly Security Daemon Started. Waiting for 00:00 (Midnight)...")

# Persistent loop preventing execution closure
while True:
    schedule.run_pending()
    time.sleep(60)  # Verify checks every 60 seconds natively
