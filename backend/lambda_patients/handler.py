import json
import os
from pymongo import MongoClient
from bson import ObjectId

MONGO_URI = os.environ.get("MONGO_URI", "your-mongo-uri-here")
client = MongoClient(MONGO_URI)
db = client["carecoord"]

def lambda_handler(event, context):
    method = event.get("httpMethod")
    path = event.get("path", "")
    
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Content-Type": "application/json"
    }

    if method == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    # GET /patients
    if method == "GET" and path == "/patients":
        patients = list(db.patients.find())
        for p in patients:
            p["_id"] = str(p["_id"])
        return {"statusCode": 200, "headers": headers, "body": json.dumps(patients)}

    # GET /patients/:id
    if method == "GET" and path.startswith("/patients/"):
        patient_id = path.split("/patients/")[-1]
        try:
            patient = db.patients.find_one({"_id": ObjectId(patient_id)})
            if not patient:
                return {"statusCode": 404, "headers": headers, "body": json.dumps({"error": "Not found"})}
            patient["_id"] = str(patient["_id"])
            return {"statusCode": 200, "headers": headers, "body": json.dumps(patient)}
        except Exception as e:
            return {"statusCode": 400, "headers": headers, "body": json.dumps({"error": str(e)})}

    # POST /patients
    if method == "POST" and path == "/patients":
        try:
            body = json.loads(event.get("body", "{}"))
            result = db.patients.insert_one(body)
            return {"statusCode": 201, "headers": headers, "body": json.dumps({"inserted_id": str(result.inserted_id)})}
        except Exception as e:
            return {"statusCode": 400, "headers": headers, "body": json.dumps({"error": str(e)})}

    # GET /beds
    if method == "GET" and path == "/beds":
        beds = list(db.beds.find())
        for b in beds:
            b["_id"] = str(b["_id"])
        return {"statusCode": 200, "headers": headers, "body": json.dumps(beds)}

    # GET /lab-results
    if method == "GET" and path == "/lab-results":
        results = list(db.lab_results.find())
        for r in results:
            r["_id"] = str(r["_id"])
        return {"statusCode": 200, "headers": headers, "body": json.dumps(results)}

    # GET /agent-events
    if method == "GET" and path == "/agent-events":
        events = list(db.agent_events.find().sort("timestamp", -1).limit(50))
        for e in events:
            e["_id"] = str(e["_id"])
        return {"statusCode": 200, "headers": headers, "body": json.dumps(events)}

    return {"statusCode": 404, "headers": headers, "body": json.dumps({"error": "Route not found"})}
