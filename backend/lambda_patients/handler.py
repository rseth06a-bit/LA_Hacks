import json
import os
from pymongo import MongoClient
from bson import ObjectId
from bson.errors import InvalidId

MONGO_URI = os.environ.get("MONGO_URI", "your-mongo-uri-here")
client = MongoClient(MONGO_URI)
db = client["carecoord"]

def _json_default(value):
    if isinstance(value, ObjectId):
        return str(value)
    raise TypeError(f"Object of type {type(value)} is not JSON serializable")

def _parse_path(event):
    return event.get("resource") or event.get("path", "")

def _response(status_code, headers, body):
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body, default=_json_default)
    }

def _normalize_patient(doc):
    if not doc:
        return None
    return {
        "_id": str(doc.get("_id", "")),
        "name": doc.get("name", "Unknown"),
        "room": doc.get("room", "Unassigned"),
        "status": doc.get("status", "admitted"),
        "priority": doc.get("priority", "medium")
    }

def lambda_handler(event, context):
    method = event.get("httpMethod")
    path = _parse_path(event)
    
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Content-Type": "application/json"
    }

    # Handle CORS preflight
    if method == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    # GET /patients
    if method == "GET" and path == "/patients":
        patients = list(db.patients.find())
        normalized = [_normalize_patient(patient) for patient in patients]
        return _response(200, headers, normalized)

    # GET /patients/:id
    if method == "GET" and "/patients/" in path:
        patient_id = event.get("pathParameters", {}).get("id") or path.split("/patients/")[-1]
        try:
            patient = db.patients.find_one({"_id": ObjectId(patient_id)})
            if not patient:
                return _response(404, headers, {"error": "Not found"})
            return _response(200, headers, _normalize_patient(patient))
        except (InvalidId, ValueError):
            return _response(400, headers, {"error": "Invalid patient id"})
        except Exception as e:
            return _response(400, headers, {"error": str(e)})

    # POST /patients
    if method == "POST" and path == "/patients":
        try:
            body = json.loads(event.get("body", "{}"))
            if not isinstance(body, dict):
                return _response(400, headers, {"error": "Invalid body"})
            result = db.patients.insert_one(body)
            return _response(201, headers, {"inserted_id": str(result.inserted_id)})
        except Exception as e:
            return _response(400, headers, {"error": str(e)})

    # GET /beds
    if method == "GET" and path == "/beds":
        beds = list(db.beds.find())
        for bed in beds:
            bed["_id"] = str(bed.get("_id", ""))
            bed["isOccupied"] = bool(bed.get("isOccupied", False))
            bed["patientId"] = bed.get("patientId")
        return _response(200, headers, beds)

    # GET /lab-results
    if method == "GET" and path == "/lab-results":
        results = list(db.lab_results.find().sort("date", -1))
        for result in results:
            result["_id"] = str(result.get("_id", ""))
            result["patientId"] = result.get("patientId", "")
            result["testName"] = result.get("testName", result.get("test", "Unknown"))
            result["result"] = result.get("result", result.get("status", "Pending"))
            result["date"] = result.get("date", result.get("timestamp"))
        return _response(200, headers, results)

    # GET /agent-events OR /events
    if method == "GET" and path in ("/agent-events", "/events"):
        events = list(db.agent_events.find().sort("timestamp", -1).limit(100))
        mapped = []
        for event_doc in events:
            mapped.append(
                {
                    "_id": str(event_doc.get("_id", "")),
                    "agentName": event_doc.get("agentName", event_doc.get("agent", "Agent")),
                    "agentType": event_doc.get("agentType", event_doc.get("type", "lab")),
                    "message": event_doc.get("message", event_doc.get("action", "Agent updated state")),
                    "timestamp": event_doc.get("timestamp")
                }
            )
        return _response(200, headers, mapped)

    return _response(404, headers, {"error": "Route not found"})