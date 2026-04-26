# CareCoord API Deploy + Test

Your `lambda_patients/handler.py` already supports:

- `GET /patients`
- `GET /patients/{id}`
- `POST /patients`
- `GET /beds`
- `GET /lab-results`
- `GET /agent-events`
- `GET /events`

Your `lambda_agents/lambda_function.py` supports:

- `POST /agents/trigger`

## 1) Deploy latest lambda code

In AWS Lambda console:

1. Open `carecoord-patients` (or equivalent)
2. Replace code with `backend/lambda_patients/handler.py`
3. Ensure env var `MONGO_URI` is set
4. Deploy

Then:

1. Open `carecoord-agents` (or equivalent)
2. Replace code with `backend/lambda_agents/lambda_function.py`
3. Ensure env vars:
   - `MONGO_URI`
   - optional: `SCHEDULING_AGENT_URL`, `LAB_AGENT_URL`, `BED_AGENT_URL`
4. Deploy

## 2) Wire API Gateway routes to lambdas

Wire these routes to the **patients lambda**:

- `GET /patients`
- `GET /patients/{id}`
- `POST /patients`
- `GET /beds`
- `GET /lab-results`
- `GET /agent-events`
- `GET /events`

Wire this route to the **agents lambda**:

- `POST /agents/trigger`

Enable CORS for all routes:

- Allow origin: `*`
- Methods: `GET,POST,OPTIONS`
- Headers: `Content-Type`

Deploy API stage after route changes.

## 3) Smoke test

Run from repo root:

```bash
bash backend/smoke_test_api.sh "https://jldwa4t8ph.execute-api.us-east-1.amazonaws.com"
```

Expected:

- `/patients` -> `200`
- `/beds` -> `200`
- `/lab-results` -> `200`
- `/agent-events` -> `200`
- `/agents/trigger` -> `200`

## 4) UI behavior after backend routes are live

The app currently uses temporary fallbacks for beds/lab/events when routes are missing.
Once all routes return `200`, we can remove those fallbacks to run strict production mode.
