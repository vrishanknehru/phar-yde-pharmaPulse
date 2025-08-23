import pickle
import json
import numpy as np
import xgboost as xgb
from sklearn.preprocessing import LabelEncoder

MODEL_PATH = "pharma_model_api/models/model.pkl"
VOCAB_PATH = "pharma_model_api/models/symptom_vocab.json"

model = None
label_encoder = None
symptom_vocab = None


def load_model():
    """
    Load the trained model, label encoder, and vocab.
    Patches XGBoost to ignore old params (like use_label_encoder).
    """
    global model, label_encoder, symptom_vocab

    print("[ml_model] 🔄 Loading model...")

    # Load bundle
    with open(MODEL_PATH, "rb") as f:
        bundle = pickle.load(f)

    model = bundle.get("model")
    label_encoder = bundle.get("label_encoder")

    # ✅ Patch: force XGBClassifier to work without use_label_encoder
    if isinstance(model, xgb.XGBClassifier):
        model.set_params(**{
            "use_label_encoder": False,   # ignore deprecated param
            "eval_metric": "mlogloss"     # required in new versions
        })

    print("[ml_model] ✅ Model + label encoder loaded.")

    # ✅ Force CPU for safety
    try:
        booster = model.get_booster()
        booster.set_param({"device": "cpu"})
        booster.set_param({"predictor": "cpu_predictor"})
        print("[ml_model] ✅ Booster forced to CPU mode.")
    except Exception as e:
        print(f"[ml_model] ⚠️ Booster patch skipped: {e}")

    # Load vocab
    with open(VOCAB_PATH, "r") as f:
        vocab_raw = json.load(f)

    if isinstance(vocab_raw, list):
        symptom_vocab = {sym: idx for idx, sym in enumerate(vocab_raw)}
    elif isinstance(vocab_raw, dict):
        symptom_vocab = vocab_raw
    else:
        raise ValueError("Invalid vocab format")

    print(f"[ml_model] ✅ Vocab loaded with {len(symptom_vocab)} symptoms.")


def predict(age: int, symptoms_passed: list):
    """
    Predict disease and risk score.
    """
    global model, label_encoder, symptom_vocab

    try:
        if model is None or symptom_vocab is None or label_encoder is None:
            raise RuntimeError("Model not loaded!")

        # Build feature vector
        X = np.zeros((1, len(symptom_vocab)))
        for symptom in symptoms_passed:
            if symptom in symptom_vocab:
                X[0, symptom_vocab[symptom]] = 1

        if "age" in symptom_vocab:
            X[0, symptom_vocab["age"]] = age

        # Predict
        y_pred = model.predict(X)[0]
        disease = label_encoder.inverse_transform([int(y_pred)])[0]

        # Probability
        y_prob = model.predict_proba(X)[0]
        risk = float(np.max(y_prob))

        return {
            "prediction": int(y_pred),
            "disease": disease,
            "risk": risk,
            "features": {
                "age": age,
                "symptoms_passed": symptoms_passed,
                "vector_len": len(symptom_vocab),
            },
        }

    except Exception as e:
        return {
            "prediction": None,
            "disease": None,
            "risk": None,
            "features": {
                "age": age,
                "symptoms_passed": symptoms_passed,
                "error": str(e),
            },
        }
