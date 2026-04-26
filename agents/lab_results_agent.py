import os
from uagents import Agent, Context, Model
from dotenv import load_dotenv

load_dotenv()

# --- Models ---
class LabResult(Model):
    patient_id: str
    patient_name: str
    test_name: str
    value: float
    unit: str
    normal_min: float
    normal_max: float

class LabResponse(Model):
    status: str
    flagged: bool
    message: str

# --- Agent setup ---
agent = Agent(
    name="lab-results-agent",
    seed="carecoord-lab-results-seed-lahacks",
    port=8002,
    endpoint=["http://127.0.0.1:8002/submit"]
)

print(f"Lab Results Agent address: {agent.address}")

# --- Helper: check if result is abnormal ---
def is_abnormal(value, normal_min, normal_max):
    return value < normal_min or value > normal_max

# --- Helper: log event (works without DB for now) ---
def log_event(patient_id, patient_name, message, flagged):
    mongo_uri = os.getenv("MONGO_URI", "placeholder")
    if mongo_uri == "placeholder":
        print(f"[LOG - no DB yet] {message}")
        return
    try:
        from pymongo import MongoClient
        client = MongoClient(mongo_uri)
        db = client["carecoord"]
        db["agent_events"].insert_one({
            "agent": "lab-results-agent",
            "patient_id": patient_id,
            "patient_name": patient_name,
            "message": message,
            "flagged": flagged,
            "type": "lab"
        })
        print(f"[DB] Event logged: {message}")
    except Exception as e:
        print(f"[DB ERROR] {e}")

# --- Main message handler ---
@agent.on_message(model=LabResult)
async def handle_lab_result(ctx: Context, sender: str, msg: LabResult):
    flagged = is_abnormal(msg.value, msg.normal_min, msg.normal_max)

    status = "ABNORMAL" if flagged else "NORMAL"
    message = (
        f"{msg.test_name} for {msg.patient_name}: "
        f"{msg.value} {msg.unit} — {status} "
        f"(normal range: {msg.normal_min}–{msg.normal_max})"
    )

    ctx.logger.info(message)
    log_event(msg.patient_id, msg.patient_name, message, flagged)

    await ctx.send(sender, LabResponse(
        status=status,
        flagged=flagged,
        message=message
    ))

if __name__ == "__main__":
    agent.run()