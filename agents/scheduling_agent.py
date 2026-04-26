import os
import threading
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from uagents import Agent, Context, Model
from dotenv import load_dotenv

load_dotenv()

# --- Flask REST API (for Lambda to call) ---
app = Flask(__name__)

# --- Models ---
class AppointmentRequest(Model):
    patient_id: str
    patient_name: str
    test_type: str
    priority: str

# --- Agent setup ---
agent = Agent(
    name="scheduling-agent",
    seed="carecoord-scheduling-seed-lahacks",
    port=8003,
    endpoint=["http://127.0.0.1:8003/submit"]
)

print(f"Scheduling Agent address: {agent.address}")

DEPARTMENT_MAP = {
    "cbc": "Hematology",
    "complete blood count": "Hematology",
    "metabolic panel": "Internal Medicine",
    "comprehensive metabolic panel": "Internal Medicine",
    "thyroid panel": "Endocrinology",
    "lipid panel": "Cardiology",
    "urinalysis": "Nephrology",
}

PRIORITY_DELAY = {"high": 0, "medium": 1, "low": 2}

def find_next_slot(priority: str) -> str:
    delay_days = PRIORITY_DELAY.get(priority.lower(), 1)
    base = datetime.now() + timedelta(days=delay_days)
    hour = max(8, base.hour + 1)
    if hour > 17:
        base += timedelta(days=1)
        hour = 9
    slot = base.replace(hour=hour, minute=0, second=0, microsecond=0)
    return slot.strftime("%Y-%m-%d at %I:%M %p")

def get_department(test_type: str) -> str:
    for key, dept in DEPARTMENT_MAP.items():
        if key in test_type.lower():
            return dept
    return "General Lab"

def log_to_mongo(patient_id, patient_name, test_type, scheduled_time):
    mongo_uri = os.getenv("MONGO_URI", "placeholder")
    if mongo_uri == "placeholder":
        print(f"[LOG] Booked {test_type} for {patient_name} at {scheduled_time}")
        return
    try:
        from pymongo import MongoClient
        client = MongoClient(mongo_uri)
        db = client["carecoord"]
        db["agent_events"].insert_one({
            "agent": "Scheduling Agent",
            "action": f"Booked {test_type} for {patient_name} on {scheduled_time}",
            "timestamp": datetime.utcnow().isoformat(),
            "type": "scheduling",
            "payload": {
                "patient_id": patient_id,
                "patient_name": patient_name,
                "test_type": test_type,
                "scheduled_time": scheduled_time
            }
        })
        db["appointments"].insert_one({
            "patient_id": patient_id,
            "patient_name": patient_name,
            "test_type": test_type,
            "scheduled_time": scheduled_time,
            "status": "confirmed",
            "created_at": datetime.utcnow().isoformat()
        })
        print(f"[DB] Booked {test_type} for {patient_name} at {scheduled_time}")
    except Exception as e:
        print(f"[DB ERROR] {e}")

# --- Flask endpoint for Lambda ---
@app.route("/schedule", methods=["POST"])
def schedule():
    data = request.json
    patient_id = data.get("patient_id")
    patient_name = data.get("patient_name")
    test_type = data.get("test_type", "Lab Test")
    priority = data.get("priority", "medium")

    scheduled_time = find_next_slot(priority)
    department = get_department(test_type)
    log_to_mongo(patient_id, patient_name, test_type, scheduled_time)

    return jsonify({
        "status": "confirmed",
        "patient_name": patient_name,
        "test_type": test_type,
        "scheduled_time": scheduled_time,
        "department": department,
        "message": f"Booked {test_type} for {patient_name} on {scheduled_time} in {department}"
    })

# --- Run Flask in background thread, uagents in main thread ---
def run_flask():
    app.run(port=8004, debug=False)

if __name__ == "__main__":
    flask_thread = threading.Thread(target=run_flask, daemon=True)
    flask_thread.start()
    print("Flask REST API running on port 8004")
    agent.run()