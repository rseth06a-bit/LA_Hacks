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
    "bed": os.environ.get("BED_AGENT_URL", ""),
    "beds": os.environ.get("BED_AGENT_URL", "")
}

def _response(status_code, headers, body):
    return {
        "statusCode": status_code,
        "headers": headers,
        "body": json.dumps(body)
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
        agent_type = body.get("agent") or body.get("type")
        payload = body.get("payload", {})

        if not agent_type:
            return _response(400, headers, {"success": False, "message": "Missing agent type"})

        patient_id = payload.get("patient_id") or payload.get("patientId") or "unknown"

        # Log the agent event to MongoDB
        db.agent_events.insert_one({
            "agent": f"{agent_type.title()} Agent",
            "agentName": f"{agent_type.title()} Agent",
            "agentType": "bed" if agent_type == "beds" else agent_type,
            "action": f"Triggered for patient {patient_id}",
            "message": f"{agent_type.title()} workflow triggered for patient {patient_id}",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "type": agent_type,
            "payload": payload
        })

        # Forward to Fetch.ai agent if URL is set
        agent_url = AGENT_ENDPOINTS.get(agent_type)
        if agent_url:
            try:
                response = requests.post(agent_url, json=payload, timeout=10)
                response.raise_for_status()
                return _response(
                    200,
                    headers,
                    {
                        "success": True,
                        "message": f"{agent_type.title()} agent triggered for patient {patient_id}",
                        "agent": agent_type,
                        "response": response.json() if response.content else {}
                    }
                )
            except requests.RequestException as exc:
                return _response(
                    502,
                    headers,
                    {
                        "success": False,
                        "message": f"Failed to reach {agent_type} agent endpoint",
                        "error": str(exc)
                    }
                )

        # If no agent URL yet, just return success (good for demo)
        return _response(
            200,
            headers,
            {
                "success": True,
                "message": f"{agent_type.title()} agent event logged for patient {patient_id}",
                "agent": agent_type
            }
        )

    except Exception as e:
        return _response(500, headers, {"success": False, "message": "Internal server error", "error": str(e)})