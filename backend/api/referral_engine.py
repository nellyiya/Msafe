from enum import Enum
from typing import Dict, Any, List
import math

class SeverityLevel(Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

def calculate_severity_score(health_data: Dict[str, Any]) -> int:
    """Calculate severity score based on health data"""
    score = 0
    
    # Blood pressure scoring
    systolic = health_data.get('systolic_bp', 0)
    diastolic = health_data.get('diastolic_bp', 0)
    
    if systolic >= 160 or diastolic >= 100:
        score += 4  # Severe hypertension
    elif systolic >= 140 or diastolic >= 90:
        score += 3  # Stage 1 hypertension
    elif systolic >= 120 or diastolic >= 80:
        score += 1  # Elevated
    
    # Blood sugar scoring
    blood_sugar = health_data.get('blood_sugar', 0)
    if blood_sugar >= 11.1:
        score += 4  # Severe diabetes
    elif blood_sugar >= 7.8:
        score += 3  # Diabetes
    elif blood_sugar >= 6.1:
        score += 1  # Pre-diabetes
    
    # Body temperature scoring
    temp = health_data.get('body_temp', 36.5)
    if temp >= 39.0:
        score += 3  # High fever
    elif temp >= 38.0:
        score += 2  # Fever
    elif temp >= 37.5:
        score += 1  # Low-grade fever
    
    # Heart rate scoring
    heart_rate = health_data.get('heart_rate', 70)
    if heart_rate >= 120 or heart_rate <= 50:
        score += 3  # Severe tachycardia or bradycardia
    elif heart_rate >= 100 or heart_rate <= 60:
        score += 1  # Mild tachycardia or bradycardia
    
    # Age factor
    age = health_data.get('age', 25)
    if age < 18 or age > 35:
        score += 2
    
    return min(score, 15)  # Cap at 15

def determine_severity_level(score: int) -> SeverityLevel:
    """Determine severity level based on score"""
    if score >= 10:
        return SeverityLevel.CRITICAL
    elif score >= 7:
        return SeverityLevel.HIGH
    elif score >= 4:
        return SeverityLevel.MEDIUM
    else:
        return SeverityLevel.LOW

def select_hospital_by_severity(severity: SeverityLevel, location: Dict[str, str]) -> str:
    """Select hospital based on severity and location"""
    # For Gasabo District, Kimironko Sector
    if severity in [SeverityLevel.CRITICAL, SeverityLevel.HIGH]:
        return "King Faisal Hospital Rwanda"  # Tertiary care
    elif severity == SeverityLevel.MEDIUM:
        return "Kibagabaga Level II Teaching Hospital"  # Secondary care
    else:
        return "Kacyiru District Hospital"  # Primary care

def get_critical_vitals(health_data: Dict[str, Any]) -> List[str]:
    """Identify critical vital signs"""
    critical = []
    
    systolic = health_data.get('systolic_bp', 0)
    diastolic = health_data.get('diastolic_bp', 0)
    if systolic >= 160 or diastolic >= 100:
        critical.append(f"Severe Hypertension (BP: {systolic}/{diastolic})")
    elif systolic >= 140 or diastolic >= 90:
        critical.append(f"Hypertension (BP: {systolic}/{diastolic})")
    
    blood_sugar = health_data.get('blood_sugar', 0)
    if blood_sugar >= 11.1:
        critical.append(f"Severe Hyperglycemia (BS: {blood_sugar} mmol/L)")
    elif blood_sugar >= 7.8:
        critical.append(f"Diabetes (BS: {blood_sugar} mmol/L)")
    
    temp = health_data.get('body_temp', 36.5)
    if temp >= 39.0:
        critical.append(f"High Fever ({temp}°C)")
    elif temp >= 38.0:
        critical.append(f"Fever ({temp}°C)")
    
    heart_rate = health_data.get('heart_rate', 70)
    if heart_rate >= 120:
        critical.append(f"Tachycardia (HR: {heart_rate} bpm)")
    elif heart_rate <= 50:
        critical.append(f"Bradycardia (HR: {heart_rate} bpm)")
    
    return critical

def generate_reasoning(severity: SeverityLevel, critical_vitals: List[str], medical_history: Dict[str, Any]) -> str:
    """Generate reasoning for referral recommendation"""
    reasons = []
    
    if severity == SeverityLevel.CRITICAL:
        reasons.append("CRITICAL: Immediate medical attention required")
    elif severity == SeverityLevel.HIGH:
        reasons.append("HIGH RISK: Urgent medical evaluation needed")
    elif severity == SeverityLevel.MEDIUM:
        reasons.append("MEDIUM RISK: Medical consultation recommended")
    
    if critical_vitals:
        reasons.append(f"Critical findings: {', '.join(critical_vitals)}")
    
    if medical_history.get('has_chronic_condition'):
        reasons.append("Pre-existing chronic condition increases risk")
    
    if medical_history.get('on_medication'):
        reasons.append("Current medication requires monitoring")
    
    return ". ".join(reasons)

def calculate_severity(symptoms, vital_signs=None):
    """Legacy function for backward compatibility"""
    if vital_signs:
        return calculate_severity_score(vital_signs)
    return 5  # Default medium severity

def select_hospital(location, severity_level, specialization=None):
    """Legacy function for backward compatibility"""
    if isinstance(severity_level, int):
        if severity_level >= 7:
            severity = SeverityLevel.HIGH
        elif severity_level >= 4:
            severity = SeverityLevel.MEDIUM
        else:
            severity = SeverityLevel.LOW
    else:
        severity = severity_level
    
    return select_hospital_by_severity(severity, location)

def get_referral_recommendation(health_data: Dict[str, Any], location: Dict[str, str] = None, medical_history: Dict[str, Any] = None):
    """Get complete referral recommendation"""
    if location is None:
        location = {}
    if medical_history is None:
        medical_history = {}
    
    # Calculate severity
    score = calculate_severity_score(health_data)
    severity = determine_severity_level(score)
    
    # Select hospital
    hospital = select_hospital_by_severity(severity, location)
    
    # Get critical vitals
    critical_vitals = get_critical_vitals(health_data)
    
    # Generate reasoning
    reasoning = generate_reasoning(severity, critical_vitals, medical_history)
    
    return {
        "severity": severity,
        "hospital": hospital,
        "score": score,
        "critical_vitals": critical_vitals,
        "reasoning": reasoning,
        "urgency": "Immediate" if severity == SeverityLevel.CRITICAL else "Urgent" if severity == SeverityLevel.HIGH else "Routine"
    }