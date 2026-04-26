import json
import os
import requests
from pymongo import MongoClient
from datetime import datetime

MONGO_URI = os.environ.get("MONGO_URI", "your-mongo-uri-here")
client = MongoClient(MONGO_URI)
db = client["carecoord"]

AGENT_ENDPOINTS = {
    "scheduling": os.environ.get("SCHEDULING_AGENT_URL", ""),
    "lab": os.environ.get("LAB_AGENT_URL", ""),
    "bed": os.environ.get("BED_AGENT_URL", "")
}

def lambda_handler(event, context):
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST,OPTIONS",
        "Content-Type": "application/json"
    }

    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": headers, "body": ""}

    try:
        body = json.loads(event.get("body", "{}"))
        agent_type = body.get("agent")
        payload = body.get("payload", {})

        if not agent_type:
            return {"statusCode": 400, "headers": headers, "body": json.dumps({"error": "Missing agent type"})}

        # Log the agent event to MongoDB
        db.agent_events.insert_one({
            "agent": f"{agent_type.title()} Agent",
            "action": f"Triggered for patient {payload.get('patient_id', 'unknown')}",
            "timestamp": datetime.utcnow().isoformat(),
            "type": agent_type,
            "payload": payload
        })

        # Forward to Fetch.ai agent if URL is set
        agent_url = AGENT_ENDPOINTS.get(agent_type)
        if agent_url:
            response = requests.post(agent_url, json=payload, timeout=10)
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps({"status": "triggered", "agent": agent_type, "response": response.json()})
            }

        # If no agent URL yet, just return success (good for demo)
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({"status": "triggered", "agent": agent_type, "message": "Agent event logged to MongoDB"})
        }

    except Exception as e:
        return {"statusCode": 500, "headers": headers, "body": json.dumps({"error": str(e)})}