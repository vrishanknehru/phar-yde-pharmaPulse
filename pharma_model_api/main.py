from fastapi import FastAPI
from pydantic import BaseModel
from typing import List
from pharma_model_api.ml_model import load_model, predict   # ✅ correct import

app = FastAPI(title="Pharma Model API")

# Load model on startup
@app.on_event("startup")
def _startup():
    try:
        load_model()
        print("[startup] ✅ Model loaded successfully")
    except Exception as e:
        print(f"[startup] ❌ Failed to load model: {e}")


class PredictRequest(BaseModel):
    age: int
    symptoms: List[str]


@app.post("/predict")
def predict_endpoint(req: PredictRequest):
    return predict(req.age, req.symptoms)


@app.get("/")
def root():
    return {"message": "Pharma Model API is running!"}
