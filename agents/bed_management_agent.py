import os
from uagents import Agent, Context, Model
from dotenv import load_dotenv

load_dotenv()

# --- Models ---
class DischargeEvent(Model):
    patient_id: str
    patient_name: str
    bed_id: str

class BedAssignment(Model):
    status: str
    bed_id: str
    message: str

# --- Agent setup ---
agent = Agent(
    name="bed-management-agent",
    seed="carecoord-bed-management-seed-lahacks",
    port=8003,
    endpoint=["http://127.0.0.1:8003/submit"]
)

print(f"Bed Management Agent address: {agent.address}")

# --- Fake bed queue for now (until MongoDB is connected) ---
waiting_patients = [
    {"patient_id": "p004", "patient_name": "James Miller"},
    {"patient_id": "p005", "patient_name": "Sofia Reyes"},
]

# --- Helper: log event (works without DB for now) ---
def log_event(patient_id, patient_name, message):
    mongo_uri = os.getenv("MONGO_URI", "placeholder")
    if mongo_uri == "placeholder":
        print(f"[LOG - no DB yet] {message}")
        return
    try:
        from pymongo import MongoClient
        client = MongoClient(mongo_uri)
        db = client["carecoord"]
        db["agent_events"].insert_one({
            "agent": "bed-management-agent",
            "patient_id": patient_id,
            "patient_name": patient_name,
            "message": message,
            "flagged": False,
            "type": "bed"
        })
        print(f"[DB] Event logged: {message}")
    except Exception as e:
        print(f"[DB ERROR] {e}")

# --- Main message handler ---
@agent.on_message(model=DischargeEvent)
async def handle_discharge(ctx: Context, sender: str, msg: DischargeEvent):
    ctx.logger.info(f"Discharge received: {msg.patient_name} from bed {msg.bed_id}")

    if waiting_patients:
        next_patient = waiting_patients.pop(0)
        message = (
            f"Bed {msg.bed_id} freed by {msg.patient_name}. "
            f"Reassigned to {next_patient['patient_name']}."
        )
        log_event(next_patient["patient_id"], next_patient["patient_name"], message)
        ctx.logger.info(message)

        await ctx.send(sender, BedAssignment(
            status="reassigned",
            bed_id=msg.bed_id,
            message=message
        ))
    else:
        message = f"Bed {msg.bed_id} freed by {msg.patient_name}. No patients in queue — bed marked available."
        log_event(msg.patient_id, msg.patient_name, message)
        ctx.logger.info(message)

        await ctx.send(sender, BedAssignment(
            status="available",
            bed_id=msg.bed_id,
            message=message
        ))

if __name__ == "__main__":
    agent.run()