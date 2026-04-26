from uagents import Agent, Context, Model
from pymongo import MongoClient
from datetime import datetime
import os

MONGO_URI = os.environ.get("MONGO_URI", "placeholder")

client = MongoClient(MONGO_URI) if MONGO_URI != "placeholder" else None
db = client["carecoord"] if client else None

class AppointmentRequest(Model):
    patient_id: str
    patient_name: str
    test_type: str
    priority: str

class AppointmentResponse(Model):
    status: str
    patient_id: str
    scheduled_time: str
    location: str
    message: str

agent = Agent(
    name="scheduling-agent",
    seed="carecoord-scheduling-seed-lahacks2026",
    port=8001,
    endpoint=["http://127.0.0.1:8001/submit"]
)

AVAILABLE_SLOTS = [
    {"time": "Today 2:30 PM", "location": "Lab Wing B", "recommended": True},
    {"time": "Today 4:00 PM", "location": "Lab Wing A", "recommended": False},
    {"time": "Tomorrow 9:00 AM", "location": "Lab Wing B", "recommended": False},
]

@agent.on_event("startup")
async def startup(ctx: Context):
    ctx.logger.info(f"Scheduling Agent started! Address: {agent.address}")

@agent.on_message(model=AppointmentRequest)
async def handle_appointment(ctx: Context, sender: str, msg: AppointmentRequest):
    ctx.logger.info(f"Scheduling {msg.patient_name} for {msg.test_type} (priority: {msg.priority})")
    
    slot = AVAILABLE_SLOTS[0] if msg.priority == "High" else AVAILABLE_SLOTS[1]
    
    if db is not None:
        db.agent_events.insert_one({
            "agent": "Scheduling Agent",
            "agentName": "Scheduling Agent",
            "agentType": "scheduling",
            "action": f"Booked {msg.test_type} for {msg.patient_name} at {slot['time']}",
            "message": f"Booked {msg.test_type} for {msg.patient_name} at {slot['time']}",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "type": "scheduling",
            "payload": {
                "patient_id": msg.patient_id,
                "test_type": msg.test_type,
                "scheduled_time": slot["time"],
                "location": slot["location"]
            }
        })
        
        db.lab_results.insert_one({
            "patientId": msg.patient_id,
            "patient": msg.patient_name,
            "testName": msg.test_type,
            "result": "Pending",
            "status": "Pending",
            "date": datetime.utcnow().isoformat() + "Z",
            "scheduled_time": slot["time"],
            "location": slot["location"],
            "timestamp": datetime.utcnow().isoformat() + "Z"
        })
    else:
        ctx.logger.info("MONGO_URI not set; skipping persistence")
    
    await ctx.send(sender, AppointmentResponse(
        status="scheduled",
        patient_id=msg.patient_id,
        scheduled_time=slot["time"],
        location=slot["location"],
        message=f"Successfully scheduled {msg.test_type} for {msg.patient_name} at {slot['time']} in {slot['location']}"
    ))

if __name__ == "__main__":
    agent.run()