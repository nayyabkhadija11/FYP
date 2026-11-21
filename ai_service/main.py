from typing import List
import joblib
import pandas as pd
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="ImmunoSphere AI Service")

# Flutter web (Chrome) se call karne ke liye zaroori
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

bundle = joblib.load("risk_model.joblib")
model = bundle["model"]
columns = bundle["columns"]


class ChildFeatures(BaseModel):
    child_id: str
    area: str
    age_days: int
    visits_due: int
    visits_missed: int
    max_days_overdue: int = 0
    days_since_last_visit: int = 0
    mean_delay_days: float = 0.0
    area_coverage: float = 85.0


def risk_level(p: float) -> str:
    if p >= 0.60:
        return "High"
    if p >= 0.35:
        return "Medium"
    return "Low"


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict")
def predict(children: List[ChildFeatures]):
    rows = []
    for c in children:
        d = c.model_dump()
        d["missed_ratio"] = round(c.visits_missed / c.visits_due, 3) if c.visits_due else 0.0
        rows.append(d)
    df = pd.DataFrame(rows)
    ids = df.pop("child_id")
    X = df.drop(columns=["area"]).reindex(columns=columns, fill_value=0)
    probs = model.predict_proba(X)[:, 1]
    return [
        {"child_id": cid, "miss_probability": round(float(p), 3), "risk_level": risk_level(float(p))}
        for cid, p in zip(ids, probs)
    ]