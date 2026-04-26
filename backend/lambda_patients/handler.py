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

    # Handle CORS preflight
    if method == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    # GET /patients
    if method == "GET" and not path.endswith(tuple("abcdefghijklmnopqrstuvwxyz0123456789") and path == "/patients"):
        patients = list(db.patients.find())
        for p in patients:
            p["_id"] = str(p["_id"])
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(patients)
        }

    # GET /patients/:id
    if method == "GET" and "/patients/" in path:
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
    if method == "POST":
        try:
            body = json.loads(event.get("body", "{}"))
            result = db.patients.insert_one(body)
            return {
                "statusCode": 201,
                "headers": headers,
                "body": json.dumps({"inserted_id": str(result.inserted_id)})
            }
        except Exception as e:
            return {"statusCode": 400, "headers": headers, "body": json.dumps({"error": str(e)})}

    return {"statusCode": 404, "headers": headers, "body": json.dumps({"error": "Route not found"})}