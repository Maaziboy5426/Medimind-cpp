from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import datetime
import random

app = FastAPI(title="MedMind AI Engine")

# --- Schemas ---

class MoodInput(BaseModel):
    text: str
    voice_transcript: Optional[str] = None

class MetricInput(BaseModel):
    sleep_hours: float
    mood_label: str
    activity_steps: int
    hydration_ml: int
    heart_rate: int

class DiseaseInput(BaseModel):
    age: int
    bmi: float
    lifestyle_score: int # 0-10
    family_history: bool
    symptoms: List[str]
    sleep_hours: float
    activity_steps: int

class SymptomInput(BaseModel):
    text: str

class CancerRiskInput(BaseModel):
    smoking: bool
    alcohol: bool
    bmi: float
    family_history: bool
    age: int

class RecommendationInput(BaseModel):
    sleep_hours: float
    activity_steps: int
    hydration_ml: int
    mood: str

# --- Mock AI Model Logic ---

class AIModelEngine:
    @staticmethod
    def predict_mood(text: str):
        # In a real scenario, we'd use transformers/BERT here
        positive_words = ['happy', 'calm', 'great', 'good', 'relaxed', 'better', 'fine']
        negative_words = ['sad', 'anxious', 'depressed', 'stressed', 'tired', 'bad', 'worried']
        
        text_lower = text.lower()
        pos_count = sum(1 for w in positive_words if w in text_lower)
        neg_count = sum(1 for w in negative_words if w in text_lower)
        
        if pos_count > neg_count:
            return random.choice(['Happy', 'Calm']), 0.85
        elif neg_count > pos_count:
            return random.choice(['Stressed', 'Anxious', 'Depressed']), 0.78
        else:
            return 'Neutral', 0.60

    @staticmethod
    def predict_stress(metrics: MetricInput):
        # Weighted logic simulating a Random Forest output
        score = 0
        if metrics.sleep_hours < 6: score += 30
        if metrics.heart_rate > 90: score += 20
        if metrics.activity_steps < 5000: score += 15
        if metrics.mood_label in ['Stressed', 'Anxious', 'Depressed']: score += 25
        if metrics.hydration_ml < 1500: score += 10
        
        score = min(score, 100)
        level = "Low" if score < 30 else "Moderate" if score < 70 else "High"
        return score, level

    @staticmethod
    def predict_disease_risks(data: DiseaseInput):
        # Simulating XGBoost risk calculation
        diabetes_risk = (data.bmi / 40.0 * 40) + (15 if data.family_history else 0) + (10 if data.lifestyle_score < 5 else 0)
        heart_risk = (data.age / 100.0 * 30) + (data.bmi / 40.0 * 25) + (15 if data.family_history else 0)
        hypertension_risk = (data.age / 100.0 * 25) + (data.bmi / 40.0 * 30) + (10 if data.lifestyle_score < 5 else 0)
        
        return {
            "diabetes": min(diabetes_risk, 100),
            "heart_disease": min(heart_risk, 100),
            "hypertension": min(hypertension_risk, 100)
        }

    @staticmethod
    def symptom_checker(text: str):
        # NLP keyword mapping
        text = text.lower()
        if 'headache' in text and 'nausea' in text:
            return ["Migraine", "Dehydration", "Tension Headache"]
        if 'cough' in text and 'fever' in text:
            return ["Common Cold", "Influenza", "COVID-19"]
        if 'chest pain' in text:
            return ["Angina", "Heartburn", "Strained Muscle"]
        return ["Unknown Condition", "Fatigue", "General Consultation Needed"]

    @staticmethod
    def cancer_risk(data: CancerRiskInput):
        score = 0
        if data.smoking: score += 40
        if data.alcohol: score += 20
        if data.bmi > 30: score += 15
        if data.family_history: score += 15
        if data.age > 50: score += 10
        return min(score, 100)

# --- Endpoints ---

class AnomalyInput(BaseModel):
    metric_name: str
    values: List[float]

class MedRiskInput(BaseModel):
    adherence_rate: float # 0.0 - 1.0
    total_meds: int
    overdue_count: int

# ... existing AIModelEngine class ...

    @staticmethod
    def detect_anomalies(metric: str, values: List[float]):
        if not values or len(values) < 3:
            return False, "Insufficient data"
        
        # Simple Z-score like anomaly detection
        avg = sum(values) / len(values)
        latest = values[-1]
        
        # If drop > 40% or spike > 40%
        if latest < avg * 0.6:
            return True, f"Significant drop detected in {metric}."
        if latest > avg * 1.4:
            return True, f"Unexpected spike detected in {metric}."
        
        return False, "Normal pattern"

    @staticmethod
    def predict_med_risk(data: MedRiskInput):
        # Isolation Forest like logic
        risk = 0
        if data.adherence_rate < 0.8: risk += 50
        if data.overdue_count > 0: risk += 30
        if data.total_meds > 5: risk += 20
        
        return min(risk, 100)

# --- Endpoints ---

@app.post("/detect-anomaly")
async def detect_anomaly(input: AnomalyInput):
    is_anomaly, message = AIModelEngine.detect_anomalies(input.metric_name, input.values)
    return {"is_anomaly": is_anomaly, "message": message}

@app.post("/medication-risk")
async def medication_risk(data: MedRiskInput):
    risk = AIModelEngine.predict_med_risk(data)
    return {"risk_score": risk}

@app.post("/predict-mood")

async def predict_mood(input: MoodInput):
    text = input.voice_transcript if input.voice_transcript else input.text
    label, confidence = AIModelEngine.predict_mood(text)
    return {"mood": label, "confidence": confidence}

@app.post("/health-score")
async def get_health_score(metrics: MetricInput):
    # Mood: 20%, Sleep: 25%, Activity: 20%, Hydration: 15%, Nutrition(Mock): 20%
    score = 0
    score += (25 if metrics.sleep_hours >= 7 else 15)
    score += (20 if metrics.activity_steps >= 10000 else 10)
    score += (20 if metrics.mood_label in ['Happy', 'Calm'] else 5)
    score += (15 if metrics.hydration_ml >= 2000 else 5)
    score += 20 # Mock nutrition
    return {"wellness_score": score}

@app.post("/predict-stress")
async def predict_stress(metrics: MetricInput):
    score, level = AIModelEngine.predict_stress(metrics)
    return {"stress_score": score, "risk_level": level}

@app.post("/predict-disease")
async def predict_disease(data: DiseaseInput):
    risks = AIModelEngine.predict_disease_risks(data)
    return {"risks": risks}

@app.post("/symptom-check")
async def symptom_check(input: SymptomInput):
    conditions = AIModelEngine.symptom_checker(input.text)
    return {"top_conditions": conditions}

@app.post("/cancer-risk")
async def cancer_risk(data: CancerRiskInput):
    score = AIModelEngine.cancer_risk(data)
    return {"risk_score": score}

@app.post("/recommendations")
async def get_recommendations(input: RecommendationInput):
    recs = []
    if input.sleep_hours < 7: recs.append("Try a consistent sleep schedule and reduce screen time before bed.")
    if input.activity_steps < 8000: recs.append("Increase daily steps; even a 10-minute walk helps.")
    if input.hydration_ml < 2000: recs.append("Set hydration reminders to reach your 2.5L goal.")
    if input.mood in ["Stressed", "Anxious"]: recs.append("Try the 4-7-8 breathing exercise in the Mental Health tab.")
    
    if not recs:
        recs.append("You're doing great! Keep up your current healthy routine.")
        
    return {"recommendations": recs}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
