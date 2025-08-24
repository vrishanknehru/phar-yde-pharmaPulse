import pickle
from sklearn.ensemble import RandomForestClassifier

# Example training
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Save model
with open("models/model.pkl", "wb") as f:
    pickle.dump(model, f)
