from __future__ import annotations

import json
import pickle
from pathlib import Path
from typing import Any, Dict, List, Optional

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# -----------------------------
# Paths
# -----------------------------
ROOT = Path(__file__).parent
MODEL_PATH = ROOT / "models" / "model.pkl"
VOCAB_PATH = ROOT / "models" / "symptom_vocab.json"
OTC_PATH = ROOT / "models" / "otc_database.json"
SAFETY_PATH = ROOT / "models" / "safety_data.json"
CLASSES_PATH = ROOT / "models" / "disease_classes.json"
DISEASE_CATEGORIES_PATH = ROOT / "models" / "disease_categories.json"

# -----------------------------
# FastAPI app
# -----------------------------
app = FastAPI(title="PharmaPulse Model API", version="3.3")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# -----------------------------
# Schemas
# -----------------------------
class PredictRequest(BaseModel):
    age: int = Field(ge=0, le=120)
    symptoms: List[str]

class PredictResponse(BaseModel):
    prediction: Optional[str] = None
    category: Optional[str] = None
    advice: str
    recommended_meds: Optional[List[str]] = None
    dosage: Optional[str] = None
    duration: Optional[str] = None
    safety_notes: Optional[str] = None
    risk: Optional[float] = None
    used_fallback: bool = False
    features: Dict[str, Any]

# -----------------------------
# Globals
# -----------------------------
model: Any = None
label_encoder: Any = None
classes_: Optional[List[Any]] = None
VOCAB: List[str] = []

OTC_DB: Dict[str, Any] = {}
SAFETY_DB: Dict[str, Any] = {}
DISEASE_CATEGORIES: Dict[str, List[str]] = {}

# -----------------------------
# Utils
# -----------------------------
def normalize_symptom(s: str) -> str:
    return s.strip().lower().replace(" ", "_").replace("-", "_")

def load_vocab() -> List[str]:
    raw = json.loads(VOCAB_PATH.read_text(encoding="utf-8"))
    return [normalize_symptom(s) for s in (raw.keys() if isinstance(raw, dict) else raw)]

def unwrap_model(obj: Any):
    if hasattr(obj, "predict"):
        return obj, None, getattr(obj, "classes_", None)
    if isinstance(obj, dict):
        for key in ["model", "clf", "classifier", "estimator"]:
            if key in obj:
                return obj[key], obj.get("label_encoder"), obj.get("classes_", None)
    raise TypeError("Loaded object has no .predict().")

def featurize(symptoms: List[str]) -> np.ndarray:
    sset = {normalize_symptom(s) for s in symptoms}
    vec = [1.0 if v in sset else 0.0 for v in VOCAB]
    return np.array([vec], dtype=np.float32)

def compute_risk_from_proba(proba_row: np.ndarray) -> float:
    return float(np.max(proba_row))

# -----------------------------
# Startup
# -----------------------------
@app.on_event("startup")
def _startup():
    global model, classes_, VOCAB, OTC_DB, SAFETY_DB, DISEASE_CATEGORIES

    VOCAB = load_vocab()

    with open(MODEL_PATH, "rb") as f:
        raw = pickle.load(f)
    model, _, classes_ = unwrap_model(raw)

    # Force load classes.json if model has none
    if not classes_ and CLASSES_PATH.exists():
        classes_ = json.loads(CLASSES_PATH.read_text(encoding="utf-8"))

    OTC_DB = json.loads(OTC_PATH.read_text(encoding="utf-8"))
    SAFETY_DB = json.loads(SAFETY_PATH.read_text(encoding="utf-8"))
    DISEASE_CATEGORIES = json.loads(DISEASE_CATEGORIES_PATH.read_text(encoding="utf-8"))

    print(f"✅ Loaded vocab ({len(VOCAB)})")
    print(f"✅ Loaded classes ({len(classes_)})")

# -----------------------------
# Routes
# -----------------------------
@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    X = featurize(req.symptoms)

    try:
        # risk score
        risk: Optional[float] = None
        if hasattr(model, "predict_proba"):
            proba = model.predict_proba(X)
            risk = compute_risk_from_proba(proba[0])

        # raw prediction
        raw_pred = model.predict(X)
        pred_value = raw_pred[0] if isinstance(raw_pred, (list, np.ndarray)) else raw_pred

        # force int → map to disease_classes.json
        disease_name = None
        if classes_:
            try:
                idx = int(pred_value)
                disease_name = str(classes_[idx])
            except Exception:
                disease_name = str(pred_value)
        else:
            disease_name = str(pred_value)

        disease_name = str(disease_name).strip()

        # category lookup
        if disease_name in DISEASE_CATEGORIES.get("green", []):
            category = "green"
        elif disease_name in DISEASE_CATEGORIES.get("red", []):
            category = "red"
        else:
            category = "unknown"

        advice = "No OTC recommendation available"
        recommended_meds, dosage, duration, safety_notes = None, None, None, None

        if category == "red":
            advice = OTC_DB.get("red_category_consultations", {}).get(
                disease_name, "Consult doctor immediately"
            )

        elif category == "green":
            disease_info = OTC_DB.get("comprehensive_otc_database", {}).get(disease_name, {})
            meds = disease_info.get("medications", [])
            safe_meds = []
            for med in meds:
                safety = SAFETY_DB.get("enhanced_beers_criteria", {}).get(med)
                if not safety:
                    safe_meds.append(med)
                else:
                    min_age = safety.get("min_age", 0) or 0
                    max_age = safety.get("max_age", 120) or 120
                    if min_age <= req.age <= max_age:
                        safe_meds.append(med)

            recommended_meds = safe_meds
            dosage = disease_info.get("dosage")
            duration = disease_info.get("duration")
            safety_notes = disease_info.get("safety_notes")
            advice = "OTC meds available"

        return PredictResponse(
            prediction=disease_name,
            category=category,
            advice=advice,
            recommended_meds=recommended_meds,
            dosage=dosage,
            duration=duration,
            safety_notes=safety_notes,
            risk=risk,
            used_fallback=False,
            features={
                "age": req.age,
                "symptoms_passed": req.symptoms,
                "vector_len": len(VOCAB),
            },
        )

    except Exception as e:
        return PredictResponse(
            prediction=None,
            category="unknown",
            advice="Heuristic risk computed (model failure)",
            risk=min(1.0, 0.02 * req.age + 0.02 * len(req.symptoms)),
            used_fallback=True,
            features={"age": req.age, "symptoms_passed": req.symptoms, "error": str(e)},
        )
