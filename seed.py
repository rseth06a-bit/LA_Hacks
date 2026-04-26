from pymongo import MongoClient

MONGO_URI = "mongodb+srv://carecoord-admin:wecareabttheworld123@collection-app.4rw1vsk.mongodb.net/?appName=Collection-App"
client = MongoClient(MONGO_URI)
db = client["carecoord"]

# Clear existing data
db.patients.delete_many({})
db.beds.delete_many({})
db.lab_results.delete_many({})
db.agent_events.delete_many({})

# Patients
db.patients.insert_many([
    {"name": "Emily Davis", "room": "401A", "age": 45, "status": "Admitted", "priority": "High", "physician": "Dr. Patel"},
    {"name": "Maria Lopez", "room": "302B", "age": 62, "status": "Admitted", "priority": "Medium", "physician": "Dr. Chen"},
    {"name": "James Chen", "room": "205C", "age": 38, "status": "Pending Discharge", "priority": "Low", "physician": "Dr. Patel"},
    {"name": "Sarah Williams", "room": "110A", "age": 71, "status": "Admitted", "priority": "High", "physician": "Dr. Nguyen"},
    {"name": "Michael Brown", "room": "307D", "age": 55, "status": "Admitted", "priority": "Medium", "physician": "Dr. Chen"},
])

# Beds
db.beds.insert_many([
    {"room": "401A", "status": "Occupied", "patient": "Emily Davis"},
    {"room": "302B", "status": "Occupied", "patient": "Maria Lopez"},
    {"room": "205C", "status": "Occupied", "patient": "James Chen"},
    {"room": "110A", "status": "Occupied", "patient": "Sarah Williams"},
    {"room": "307D", "status": "Occupied", "patient": "Michael Brown"},
    {"room": "201A", "status": "Available", "patient": None},
    {"room": "204B", "status": "Available", "patient": None},
    {"room": "310C", "status": "Cleaning", "patient": None},
    {"room": "412A", "status": "Available", "patient": None},
    {"room": "105B", "status": "Cleaning", "patient": None},
])

# Lab Results
db.lab_results.insert_many([
    {"patient": "Emily Davis", "test": "Complete Blood Count", "status": "Abnormal", "timestamp": "2026-04-25T13:00:00", "values": [
        {"name": "WBC", "value": "11.2", "range": "4.5-10.0", "flag": "High"},
        {"name": "RBC", "value": "3.8", "range": "4.2-5.4", "flag": "Low"},
        {"name": "Hemoglobin", "value": "11.1", "range": "12.0-16.0", "flag": "Low"},
        {"name": "Platelets", "value": "250", "range": "150-400", "flag": "Normal"},
    ]},
    {"patient": "Maria Lopez", "test": "Comprehensive Metabolic Panel", "status": "Normal", "timestamp": "2026-04-25T12:30:00", "values": [
        {"name": "Glucose", "value": "95", "range": "70-100", "flag": "Normal"},
        {"name": "Creatinine", "value": "0.9", "range": "0.6-1.2", "flag": "Normal"},
        {"name": "Sodium", "value": "140", "range": "136-145", "flag": "Normal"},
    ]},
    {"patient": "Michael Brown", "test": "Thyroid Panel", "status": "Abnormal", "timestamp": "2026-04-25T12:00:00", "values": [
        {"name": "TSH", "value": "6.8", "range": "0.4-4.0", "flag": "High"},
        {"name": "T4", "value": "0.7", "range": "0.8-1.8", "flag": "Low"},
    ]},
])

# Agent Events
db.agent_events.insert_many([
    {"agent": "Lab Results Agent", "action": "Flagged 2 abnormalities for Emily Davis", "timestamp": "2026-04-25T13:01:00", "type": "lab"},
    {"agent": "Scheduling Agent", "action": "Booked CBC follow-up for Emily Davis at 3:00 PM", "timestamp": "2026-04-25T13:02:00", "type": "scheduling"},
    {"agent": "Bed Management Agent", "action": "Marked Room 310C for cleaning after discharge", "timestamp": "2026-04-25T12:45:00", "type": "bed"},
    {"agent": "Lab Results Agent", "action": "Flagged abnormal TSH for Michael Brown", "timestamp": "2026-04-25T12:01:00", "type": "lab"},
])

print("✅ Seed complete! All collections populated.")