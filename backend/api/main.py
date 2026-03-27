from fastapi import FastAPI, HTTPException, Depends, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from datetime import datetime, timedelta
import joblib
import pandas as pd
import os
import sys
import json

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import engine, get_db, Base
from models import User, Mother, HealthRecord, Visit, Referral, UserRole, UserStatus, ReferralStatus, SeverityLevel, ChatRoom, ChatMessage
from schemas import *
from auth import get_password_hash, verify_password, create_access_token, get_current_user, get_approved_user, get_admin_user
from referral_engine import calculate_severity, select_hospital, get_referral_recommendation

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="MamaSafe API", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load ML models
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.abspath(os.path.join(BASE_DIR, "..", "model"))

print(f"Looking for models in: {MODEL_DIR}")
try:
    rf_model = joblib.load(os.path.join(MODEL_DIR, "rf_model.pkl"))
    scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
    label_encoder = joblib.load(os.path.join(MODEL_DIR, "label_encoder.pkl"))
    print("✅ Models loaded successfully")
except Exception as e:
    print(f"❌ Failed to load models: {e}")
    print("⚠️  Prediction endpoint will not work, but other endpoints are fine")
    rf_model = None
    scaler = None
    label_encoder = None

# ==================== AUTH ENDPOINTS ====================

@app.post("/auth/register", response_model=UserResponse)
def register(user: UserRegister, db: Session = Depends(get_db)):
    # Check if email already exists
    if db.query(User).filter(User.email == user.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Validate role-specific fields
    if user.role == UserRole.CHW:
        if not user.district or not user.sector:
            raise HTTPException(status_code=400, detail="CHW must provide District and Sector")
        if user.district.lower() != "gasabo" or user.sector.lower() != "kimironko":
            raise HTTPException(status_code=400, detail="System only accepts CHWs from Gasabo District, Kimironko Sector")
    
    if user.role == UserRole.HEALTHCARE_PRO:
        if not user.facility:
            raise HTTPException(status_code=400, detail="Hospital staff must provide Hospital Name")
        # Validate hospital is one of the three approved
        valid_hospitals = ["King Faisal Hospital Rwanda", "Kibagabaga Level II Teaching Hospital", "Kacyiru District Hospital"]
        if user.facility not in valid_hospitals:
            raise HTTPException(status_code=400, detail=f"Hospital must be one of: {', '.join(valid_hospitals)}")
    
    if user.role == UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Admin accounts cannot be created through registration")
    
    # Create user
    db_user = User(
        name=user.name,
        email=user.email,
        phone=user.phone,
        password_hash=get_password_hash(user.password),
        role=user.role,
        district=user.district,
        sector=user.sector,
        cell=user.cell,
        village=user.village,
        facility=user.facility,
        is_approved=False,
        status=UserStatus.PENDING
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/auth/login", response_model=Token)
def login(user: UserLogin, db: Session = Depends(get_db)):
    # Hardcoded admin credentials
    if user.email.lower() == "admin@mamasafe.com" and user.password == "Admin@2024":
        # Check if admin exists in database
        admin_user = db.query(User).filter(User.email == "admin@mamasafe.com").first()
        if not admin_user:
            # Create admin user if doesn't exist
            admin_user = User(
                name="System Admin",
                email="admin@mamasafe.com",
                phone="+250788000000",
                password_hash=get_password_hash("Admin@2024"),
                role=UserRole.ADMIN,
                is_approved=True,
                status=UserStatus.ACTIVE
            )
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
        
        access_token = create_access_token(data={"sub": admin_user.email})
        return {"access_token": access_token, "token_type": "bearer"}
    
    db_user = db.query(User).filter(User.email == user.email).first()
    
    # Check if user exists and password is correct
    if not db_user or not verify_password(user.password, db_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    
    # Check account status
    if db_user.status == UserStatus.PENDING:
        raise HTTPException(status_code=403, detail="Your account is awaiting Admin approval")
    
    if db_user.status == UserStatus.SUSPENDED:
        raise HTTPException(status_code=403, detail="Your registration was rejected. Please contact Admin")
    
    if not db_user.is_approved:
        raise HTTPException(status_code=403, detail="Your account is awaiting Admin approval")
    
    # Generate token
    access_token = create_access_token(data={"sub": db_user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return current_user

# ==================== ADMIN ENDPOINTS ====================

@app.get("/admin/users/pending", response_model=list[UserResponse])
def get_pending_users(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    return db.query(User).filter(User.is_approved == False).all()

@app.put("/admin/users/{user_id}/approve")
def approve_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.is_approved = True
    user.status = UserStatus.ACTIVE
    db.commit()
    return {"message": "User approved"}

@app.put("/admin/users/{user_id}/reject")
def reject_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    return {"message": "User rejected"}

@app.get("/admin/users/chws")
def get_all_chws(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get all CHWs with their stats"""
    chws = db.query(User).filter(User.role == UserRole.CHW).all()
    result = []
    for chw in chws:
        mothers_count = db.query(Mother).filter(Mother.created_by_chw_id == chw.id).count()
        assessments_count = db.query(HealthRecord).join(Mother).filter(Mother.created_by_chw_id == chw.id).count()
        referrals_count = db.query(Referral).filter(Referral.chw_id == chw.id).count()
        
        result.append({
            "id": chw.id,
            "name": chw.name,
            "email": chw.email,
            "phone": chw.phone,
            "sector": chw.sector,
            "cell": chw.cell,
            "village": chw.village,
            "status": chw.status.value if chw.status else "active",
            "is_approved": chw.is_approved,
            "mothers_count": mothers_count,
            "assessments_count": assessments_count,
            "referrals_count": referrals_count,
        })
    return result

@app.get("/admin/users/healthcare-pros")
def get_all_healthcare_pros(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get all healthcare professionals with their stats"""
    pros = db.query(User).filter(User.role == UserRole.HEALTHCARE_PRO).all()
    result = []
    for pro in pros:
        referrals_count = db.query(Referral).filter(Referral.hospital.ilike(f"%{pro.facility}%")).count()
        completed_count = db.query(Referral).filter(
            Referral.hospital.ilike(f"%{pro.facility}%"),
            Referral.status == ReferralStatus.COMPLETED
        ).count()
        
        result.append({
            "id": pro.id,
            "name": pro.name,
            "email": pro.email,
            "phone": pro.phone,
            "facility": pro.facility,
            "status": pro.status.value if pro.status else "active",
            "is_approved": pro.is_approved,
            "referrals_count": referrals_count,
            "completed_count": completed_count,
        })
    return result

@app.put("/admin/users/{user_id}")
def update_user(user_id: int, update_data: dict, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Update user information"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if 'name' in update_data:
        user.name = update_data['name']
    if 'phone' in update_data:
        user.phone = update_data['phone']
    if 'email' in update_data:
        user.email = update_data['email']
    if 'sector' in update_data:
        user.sector = update_data['sector']
    if 'cell' in update_data:
        user.cell = update_data['cell']
    if 'village' in update_data:
        user.village = update_data['village']
    if 'facility' in update_data:
        user.facility = update_data['facility']
    if 'status' in update_data:
        user.status = UserStatus(update_data['status'])
    
    db.commit()
    db.refresh(user)
    return {"message": "User updated successfully"}

@app.delete("/admin/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Delete a user"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.role == UserRole.ADMIN:
        raise HTTPException(status_code=403, detail="Cannot delete admin users")
    
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}

@app.get("/admin/mothers/all")
def get_all_mothers_admin(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get all mothers for admin"""
    mothers = db.query(Mother).order_by(Mother.created_at.desc()).all()
    result = []
    for mother in mothers:
        chw = db.query(User).filter(User.id == mother.created_by_chw_id).first()
        result.append({
            "id": mother.id,
            "name": mother.name,
            "age": mother.age,
            "phone": mother.phone,
            "province": mother.province,
            "district": mother.district,
            "sector": mother.sector,
            "cell": mother.cell,
            "village": mother.village,
            "current_risk_level": mother.current_risk_level,
            "created_at": mother.created_at.isoformat() if mother.created_at else None,
            "chw": {"id": chw.id, "name": chw.name} if chw else None,
        })
    return result

@app.put("/admin/mothers/{mother_id}")
def update_mother(mother_id: int, update_data: dict, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Update mother information"""
    mother = db.query(Mother).filter(Mother.id == mother_id).first()
    if not mother:
        raise HTTPException(status_code=404, detail="Mother not found")
    
    if 'name' in update_data:
        mother.name = update_data['name']
    if 'age' in update_data:
        mother.age = update_data['age']
    if 'phone' in update_data:
        mother.phone = update_data['phone']
    if 'sector' in update_data:
        mother.sector = update_data['sector']
    if 'cell' in update_data:
        mother.cell = update_data['cell']
    if 'village' in update_data:
        mother.village = update_data['village']
    
    db.commit()
    db.refresh(mother)
    return {"message": "Mother updated successfully"}

@app.delete("/admin/mothers/{mother_id}")
def delete_mother(mother_id: int, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Delete a mother and all related records"""
    mother = db.query(Mother).filter(Mother.id == mother_id).first()
    if not mother:
        raise HTTPException(status_code=404, detail="Mother not found")
    
    db.query(HealthRecord).filter(HealthRecord.mother_id == mother_id).delete()
    db.query(Visit).filter(Visit.mother_id == mother_id).delete()
    db.query(Referral).filter(Referral.mother_id == mother_id).delete()
    db.delete(mother)
    db.commit()
    return {"message": "Mother deleted successfully"}

@app.get("/admin/test")
def test_admin_auth(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Test endpoint to verify admin authentication"""
    return {
        "message": "Admin authentication successful",
        "admin_user": {
            "id": admin.id,
            "name": admin.name,
            "email": admin.email,
            "role": admin.role.value
        }
    }

@app.get("/admin/dashboard")
def admin_dashboard(days: int = 30, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    try:
        from sqlalchemy import case
        
        # Basic counts
        total_chws = db.query(User).filter(User.role == UserRole.CHW, User.is_approved == True).count()
        total_hospitals = db.query(User).filter(User.role == UserRole.HEALTHCARE_PRO, User.is_approved == True).count()
        total_mothers = db.query(Mother).count()
        total_referrals = db.query(Referral).count()
        
        # Risk level counts
        high_risk = db.query(Mother).filter(Mother.current_risk_level == "High").count()
        medium_risk = db.query(Mother).filter(
            or_(Mother.current_risk_level == "Medium", Mother.current_risk_level == "Mid")
        ).count()
        low_risk = db.query(Mother).filter(Mother.current_risk_level == "Low").count()
        
        # Referral status counts
        pending_referrals = 0
        try:
            pending_referrals = db.query(Referral).filter(Referral.status == ReferralStatus.PENDING).count()
        except:
            pass
        
        # Geographic distribution (Kimironko Sector)
        location_data = []
        try:
            locations = db.query(
                Mother.cell,
                func.count(Mother.id).label('total'),
                func.sum(case((Mother.current_risk_level == 'High', 1), else_=0)).label('high_risk'),
                func.sum(case((or_(Mother.current_risk_level == 'Medium', Mother.current_risk_level == 'Mid'), 1), else_=0)).label('medium_risk'),
                func.sum(case((Mother.current_risk_level == 'Low', 1), else_=0)).label('low_risk')
            ).filter(
                Mother.sector == 'Kimironko'
            ).group_by(Mother.cell).all()
            
            for loc in locations:
                if loc[0]:
                    location_data.append({
                        "location": loc[0],
                        "total": loc[1],
                        "high_risk": loc[2],
                        "medium_risk": loc[3],
                        "low_risk": loc[4]
                    })
        except Exception as e:
            print(f"Error getting location data: {e}")
        
        return {
            "total_mothers": total_mothers,
            "high_risk": high_risk,
            "medium_risk": medium_risk,
            "low_risk": low_risk,
            "total_referrals": total_referrals,
            "pending_referrals": pending_referrals,
            "active_chws": total_chws,
            "active_hospitals": total_hospitals,
            "locations": location_data
        }
    except Exception as e:
        print(f"Dashboard error: {e}")
        return {
            "total_mothers": 0,
            "high_risk": 0,
            "medium_risk": 0,
            "low_risk": 0,
            "total_referrals": 0,
            "pending_referrals": 0,
            "active_chws": 0,
            "active_hospitals": 0,
            "locations": []
        }

@app.get("/admin/chw-performance")
def chw_performance(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get CHW performance metrics based on response times"""
    chws = db.query(User).filter(User.role == UserRole.CHW, User.is_approved == True).all()
    
    performance_data = []
    for chw in chws:
        referrals = db.query(Referral).filter(
            Referral.chw_id == chw.id,
            Referral.risk_detected_time.isnot(None),
            Referral.chw_confirmed_time.isnot(None)
        ).all()
        
        if referrals:
            total_response_time = sum([
                (r.chw_confirmed_time - r.risk_detected_time).total_seconds() / 60
                for r in referrals
            ])
            avg_response_minutes = total_response_time / len(referrals)
            
            # Categorize response time
            if avg_response_minutes <= 30:
                category = "Excellent"
            elif avg_response_minutes <= 120:
                category = "Moderate"
            else:
                category = "Slow"
            
            performance_data.append({
                "chw_name": chw.name,
                "chw_id": chw.id,
                "total_referrals": len(referrals),
                "avg_response_minutes": round(avg_response_minutes, 1),
                "category": category
            })
    
    # Sort by response time
    performance_data.sort(key=lambda x: x['avg_response_minutes'])
    
    return performance_data

@app.get("/admin/hospital-performance")
def hospital_performance(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get hospital performance metrics based on response times"""
    hospitals = db.query(User).filter(User.role == UserRole.HEALTHCARE_PRO, User.is_approved == True).all()
    
    performance_data = []
    for hospital in hospitals:
        referrals = db.query(Referral).filter(
            Referral.hospital.ilike(f"%{hospital.facility}%"),
            Referral.chw_confirmed_time.isnot(None),
            Referral.hospital_received_time.isnot(None)
        ).all()
        
        if referrals:
            total_response_time = sum([
                (r.hospital_received_time - r.chw_confirmed_time).total_seconds() / 60
                for r in referrals
            ])
            avg_response_minutes = total_response_time / len(referrals)
            
            # Categorize response time
            if avg_response_minutes <= 60:
                category = "Efficient"
            elif avg_response_minutes <= 180:
                category = "Acceptable"
            else:
                category = "Delayed"
            
            emergency_count = db.query(Referral).filter(
                Referral.hospital.ilike(f"%{hospital.facility}%"),
                Referral.status == ReferralStatus.EMERGENCY_CARE_REQUIRED
            ).count()
            
            total_referrals_count = db.query(Referral).filter(
                Referral.hospital.ilike(f"%{hospital.facility}%")
            ).count()
            
            emergency_rate = (emergency_count / total_referrals_count * 100) if total_referrals_count > 0 else 0
            
            performance_data.append({
                "hospital_name": hospital.facility,
                "hospital_id": hospital.id,
                "total_referrals": total_referrals_count,
                "avg_response_minutes": round(avg_response_minutes, 1),
                "emergency_cases": emergency_count,
                "emergency_response_rate": round(emergency_rate, 1),
                "category": category
            })
    
    # Sort by response time
    performance_data.sort(key=lambda x: x['avg_response_minutes'])
    
    return performance_data

@app.get("/admin/analytics/risk-trends")
def risk_trends(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get monthly risk trends"""
    # Get risk distribution for last 6 months
    six_months_ago = datetime.utcnow() - timedelta(days=180)
    
    health_records = db.query(
        func.strftime('%Y-%m', HealthRecord.created_at).label('month'),
        HealthRecord.risk_level,
        func.count(HealthRecord.id).label('count')
    ).filter(
        HealthRecord.created_at >= six_months_ago
    ).group_by('month', HealthRecord.risk_level).all()
    
    trends = {}
    for record in health_records:
        month = record[0]
        risk_level = record[1]
        count = record[2]
        
        if month not in trends:
            trends[month] = {"Low": 0, "Medium": 0, "High": 0}
        trends[month][risk_level] = count
    
    return trends

@app.get("/admin/analytics/referral-distribution")
def referral_distribution(days: int = 30, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get referral status distribution"""
    from sqlalchemy import text
    
    # Get referral counts by status using raw SQL
    status_counts = db.execute(
        text("""
            SELECT status, COUNT(*) as count
            FROM referrals
            GROUP BY status
        """)
    ).fetchall()
    
    result = []
    for status, count in status_counts:
        result.append({
            "status": status,
            "count": count
        })
    
    return {"referrals": result}

@app.get("/admin/analytics/chw-activity")
def chw_activity(days: int = 30, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get CHW activity monitoring data"""
    chws = db.query(User).filter(User.role == UserRole.CHW, User.is_approved == True).all()
    
    activity_data = []
    for chw in chws:
        mothers_registered = db.query(Mother).filter(Mother.created_by_chw_id == chw.id).count()
        referrals_sent = db.query(Referral).filter(Referral.chw_id == chw.id).count()
        assessments_completed = db.query(HealthRecord).join(Mother).filter(Mother.created_by_chw_id == chw.id).count()
        high_risk_cases = db.query(Mother).filter(
            Mother.created_by_chw_id == chw.id,
            Mother.current_risk_level == "High"
        ).count()
        
        activity_data.append({
            "name": chw.name,
            "id": chw.id,
            "mothers_registered": mothers_registered,
            "assessments_completed": assessments_completed,
            "referrals_sent": referrals_sent,
            "high_risk_cases": high_risk_cases
        })
    
    # Sort by mothers registered
    activity_data.sort(key=lambda x: x['mothers_registered'], reverse=True)
    
    return activity_data

@app.get("/admin/analytics/hospital-workload")
def hospital_workload(days: int = 30, db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get hospital activity monitoring data"""
    from sqlalchemy import text
    
    # Get hospital workload using raw SQL to avoid enum issues
    workload_raw = db.execute(
        text("""
            SELECT 
                hospital,
                COUNT(*) as total_referrals,
                SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) as pending,
                SUM(CASE WHEN status = 'Appointment Scheduled' THEN 1 ELSE 0 END) as scheduled,
                SUM(CASE WHEN status = 'Completed' THEN 1 ELSE 0 END) as completed
            FROM referrals
            GROUP BY hospital
        """)
    ).fetchall()
    
    result = []
    for row in workload_raw:
        result.append({
            "name": row[0],
            "total_referrals": row[1],
            "pending": row[2],
            "scheduled": row[3],
            "completed": row[4]
        })
    
    return result

# ==================== MOTHER ENDPOINTS ====================

@app.post("/mothers", response_model=MotherResponse)
def create_mother(mother: MotherCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    db_mother = Mother(**mother.dict(), created_by_chw_id=current_user.id)
    db.add(db_mother)
    db.commit()
    db.refresh(db_mother)
    return db_mother

@app.get("/mothers", response_model=list[MotherResponse])
def get_mothers(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    query = db.query(Mother)
    if current_user.role == UserRole.CHW:
        query = query.filter(Mother.created_by_chw_id == current_user.id)
    
    mothers = query.order_by(Mother.created_at.desc()).all()
    
    # Get all mothers with scheduled appointments in one query
    from sqlalchemy import text
    mothers_with_appointments = set()
    try:
        result = db.execute(
            text("""
                SELECT DISTINCT mother_id 
                FROM referrals 
                WHERE (status = 'APPOINTMENT_SCHEDULED' OR status = 'Appointment Scheduled')
                AND chw_id = :chw_id
            """),
            {"chw_id": current_user.id}
        ).fetchall()
        mothers_with_appointments = {row[0] for row in result}
        print(f'🔍 Mothers with appointments for CHW {current_user.id}: {mothers_with_appointments}')
    except Exception as e:
        print(f'❌ Error getting mothers with appointments: {e}')
        pass
    
    # Manually build response to avoid enum issues
    result = []
    for mother in mothers:
        try:
            result.append({
                "id": mother.id,
                "name": mother.name,
                "age": mother.age,
                "phone": mother.phone,
                "province": mother.province,
                "district": mother.district,
                "sector": mother.sector,
                "cell": mother.cell,
                "village": mother.village,
                "pregnancy_start_date": mother.pregnancy_start_date,
                "due_date": mother.due_date,
                "created_by_chw_id": mother.created_by_chw_id,
                "current_risk_level": mother.current_risk_level,
                "has_allergies": mother.has_allergies,
                "has_chronic_condition": mother.has_chronic_condition,
                "on_medication": mother.on_medication,
                "created_at": mother.created_at,
                "hasScheduledAppointment": mother.id in mothers_with_appointments
            })
        except Exception as e:
            # If there's an error with this mother, add with hasScheduledAppointment = False
            result.append({
                "id": mother.id,
                "name": mother.name,
                "age": mother.age,
                "phone": mother.phone,
                "province": mother.province,
                "district": mother.district,
                "sector": mother.sector,
                "cell": mother.cell,
                "village": mother.village,
                "pregnancy_start_date": mother.pregnancy_start_date,
                "due_date": mother.due_date,
                "created_by_chw_id": mother.created_by_chw_id,
                "current_risk_level": mother.current_risk_level,
                "has_allergies": mother.has_allergies,
                "has_chronic_condition": mother.has_chronic_condition,
                "on_medication": mother.on_medication,
                "created_at": mother.created_at,
                "hasScheduledAppointment": False
            })
    
    return result

@app.get("/mothers/{mother_id}")
def get_mother(mother_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    mother = db.query(Mother).filter(Mother.id == mother_id).first()
    
    if not mother:
        raise HTTPException(status_code=404, detail="Mother not found")
    
    # Check if mother has scheduled appointment (for current CHW if CHW is logged in)
    from sqlalchemy import text
    has_appointment = False
    try:
        if current_user.role.value == 'CHW':
            # For CHW, only check appointments they created
            result = db.execute(
                text("""
                    SELECT COUNT(*) FROM referrals 
                    WHERE mother_id = :mother_id 
                    AND chw_id = :chw_id
                    AND (status = 'APPOINTMENT_SCHEDULED' OR status = 'Appointment Scheduled')
                """),
                {"mother_id": mother_id, "chw_id": current_user.id}
            ).scalar()
        else:
            # For admin/healthcare pro, check all appointments for this mother
            result = db.execute(
                text("""
                    SELECT COUNT(*) FROM referrals 
                    WHERE mother_id = :mother_id 
                    AND (status = 'APPOINTMENT_SCHEDULED' OR status = 'Appointment Scheduled')
                """),
                {"mother_id": mother_id}
            ).scalar()
        has_appointment = result > 0
    except Exception as e:
        print(f'Error checking appointments: {e}')
        pass
    
    # Manually query referrals to avoid enum issues
    from sqlalchemy import text
    referrals_raw = db.execute(
        text("""
            SELECT r.id, r.mother_id, r.chw_id, r.healthcare_pro_id, r.hospital, 
                   r.severity, r.status, r.appointment_date, r.appointment_time, 
                   r.department, r.created_at,
                   u.id as doctor_id, u.name as doctor_name, u.phone as doctor_phone
            FROM referrals r
            LEFT JOIN users u ON r.healthcare_pro_id = u.id
            WHERE r.mother_id = :mother_id
        """),
        {"mother_id": mother_id}
    ).fetchall()
    
    referrals_data = []
    for ref in referrals_raw:
        ref_dict = {
            "id": ref[0],
            "mother_id": ref[1],
            "chw_id": ref[2],
            "healthcare_pro_id": ref[3],
            "hospital": ref[4],
            "severity": ref[5],
            "status": ref[6],
            "appointment_date": ref[7],
            "appointment_time": ref[8],
            "department": ref[9],
            "created_at": ref[10],
            "healthcare_pro": {
                "id": ref[11],
                "name": ref[12],
                "phone": ref[13],
            } if ref[11] else None
        }
        referrals_data.append(ref_dict)
    
    return {
        "id": mother.id,
        "name": mother.name,
        "age": mother.age,
        "phone": mother.phone,
        "province": mother.province,
        "district": mother.district,
        "sector": mother.sector,
        "cell": mother.cell,
        "village": mother.village,
        "pregnancy_start_date": mother.pregnancy_start_date.isoformat() if mother.pregnancy_start_date else None,
        "due_date": mother.due_date.isoformat() if mother.due_date else None,
        "created_by_chw_id": mother.created_by_chw_id,
        "current_risk_level": mother.current_risk_level,
        "has_allergies": mother.has_allergies,
        "has_chronic_condition": mother.has_chronic_condition,
        "on_medication": mother.on_medication,
        "created_at": mother.created_at.isoformat() if mother.created_at else None,
        "hasScheduledAppointment": has_appointment,
        "referrals": referrals_data
    }

# ==================== HEALTH RECORD ENDPOINTS ====================

@app.post("/health-records", response_model=HealthRecordResponse)
def create_health_record(record: HealthRecordCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    db_record = HealthRecord(**record.dict())
    db.add(db_record)
    
    # Update mother's current risk level
    mother = db.query(Mother).filter(Mother.id == record.mother_id).first()
    if mother:
        mother.current_risk_level = record.risk_level
    
    db.commit()
    db.refresh(db_record)
    return db_record

@app.get("/health-records/{mother_id}", response_model=list[HealthRecordResponse])
def get_health_records(mother_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    return db.query(HealthRecord).filter(HealthRecord.mother_id == mother_id).order_by(HealthRecord.created_at.desc()).all()

# ==================== VISIT ENDPOINTS ====================

@app.post("/visits", response_model=VisitResponse)
def create_visit(visit: VisitCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    db_visit = Visit(**visit.dict(), chw_id=current_user.id)
    db.add(db_visit)
    db.commit()
    db.refresh(db_visit)
    return db_visit

@app.get("/visits/due-today")
def get_visits_due_today(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    today = datetime.utcnow().date()
    visits = db.query(Visit).filter(
        Visit.chw_id == current_user.id,
        func.date(Visit.next_visit_date) == today
    ).all()
    return visits

@app.get("/visits/overdue")
def get_overdue_visits(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    today = datetime.utcnow()
    visits = db.query(Visit).filter(
        Visit.chw_id == current_user.id,
        Visit.next_visit_date < today,
        Visit.completed == False
    ).all()
    return visits

# ==================== REFERRAL ENDPOINTS ====================

@app.post("/referrals", response_model=ReferralResponse)
def create_referral(referral: ReferralCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    # Set CHW confirmed time when creating referral
    db_referral = Referral(
        **referral.dict(),
        chw_id=current_user.id,
        chw_confirmed_time=datetime.utcnow()
    )
    db.add(db_referral)
    db.commit()
    db.refresh(db_referral)
    return db_referral

@app.get("/referrals/incoming")
def get_incoming_referrals(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    if current_user.role != UserRole.HEALTHCARE_PRO:
        raise HTTPException(status_code=403, detail="Healthcare professional access required")
    
    # Use raw SQL to avoid enum issues
    from sqlalchemy import text
    referrals_raw = db.execute(
        text("""
            SELECT r.id, r.mother_id, r.chw_id, r.healthcare_pro_id, r.hospital, 
                   r.severity, r.notes, r.diagnosis, r.treatment_notes, r.status,
                   r.risk_detected_time, r.chw_confirmed_time, r.hospital_received_time,
                   r.created_at, r.completed_at, r.appointment_date, r.appointment_time, r.department,
                   m.id as m_id, m.name as m_name, m.age as m_age, m.phone as m_phone,
                   m.current_risk_level, m.province, m.district, m.sector, m.cell, m.village,
                   m.has_allergies, m.has_chronic_condition, m.on_medication,
                   c.id as c_id, c.name as c_name, c.phone as c_phone,
                   h.systolic_bp, h.diastolic_bp, h.blood_sugar, h.body_temp, h.heart_rate
            FROM referrals r
            LEFT JOIN mothers m ON r.mother_id = m.id
            LEFT JOIN users c ON r.chw_id = c.id
            LEFT JOIN health_records h ON m.id = h.mother_id
            WHERE r.hospital LIKE :facility
            ORDER BY r.created_at DESC
        """),
        {"facility": f"%{current_user.facility}%"}
    ).fetchall()
    
    # Build detailed response
    result = []
    for ref in referrals_raw:
        ref_dict = {
            "id": ref[0],
            "mother_id": ref[1],
            "chw_id": ref[2],
            "healthcare_pro_id": ref[3],
            "hospital": ref[4],
            "severity": ref[5],
            "notes": ref[6],
            "diagnosis": ref[7],
            "treatment_notes": ref[8],
            "status": ref[9],
            "risk_detected_time": ref[10],
            "chw_confirmed_time": ref[11],
            "hospital_received_time": ref[12],
            "created_at": ref[13],
            "completed_at": ref[14],
            "appointment_date": ref[15],
            "appointment_time": ref[16],
            "department": ref[17],
            "mother": {
                "id": ref[18],
                "name": ref[19],
                "age": ref[20],
                "phone": ref[21],
                "risk_level": ref[22],
                "province": ref[23],
                "district": ref[24],
                "sector": ref[25],
                "cell": ref[26],
                "village": ref[27],
                "has_allergies": ref[28],
                "has_chronic_condition": ref[29],
                "on_medication": ref[30],
            } if ref[18] else None,
            "chw": {
                "id": ref[31],
                "name": ref[32],
                "phone": ref[33],
            } if ref[31] else None,
            "health_readings": {
                "systolic_bp": ref[34],
                "diastolic_bp": ref[35],
                "blood_sugar": ref[36],
                "body_temp": ref[37],
                "heart_rate": ref[38],
            } if ref[34] else None
        }
        result.append(ref_dict)
    
    return result

@app.put("/referrals/{referral_id}", response_model=ReferralResponse)
def update_referral(referral_id: int, update: ReferralUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    referral = db.query(Referral).filter(Referral.id == referral_id).first()
    if not referral:
        raise HTTPException(status_code=404, detail="Referral not found")
    
    if update.healthcare_pro_id:
        referral.healthcare_pro_id = update.healthcare_pro_id
    if update.diagnosis:
        referral.diagnosis = update.diagnosis
    if update.treatment_notes:
        referral.treatment_notes = update.treatment_notes
    
    # Handle appointment scheduling/rescheduling
    if update.appointment_date:
        referral.appointment_date = update.appointment_date
    if update.appointment_time:
        referral.appointment_time = update.appointment_time
    if update.department:
        referral.department = update.department
    
    if update.hospital_received_time:
        referral.hospital_received_time = update.hospital_received_time
    
    if update.status:
        referral.status = update.status
        # Set hospital_received_time when status changes to RECEIVED
        if update.status == ReferralStatus.RECEIVED and not referral.hospital_received_time:
            referral.hospital_received_time = datetime.utcnow()
        # Set completed_at when status changes to COMPLETED
        elif update.status == ReferralStatus.COMPLETED:
            referral.completed_at = datetime.utcnow()
        # When scheduling appointment, ensure status is set to APPOINTMENT_SCHEDULED
        elif update.status == ReferralStatus.APPOINTMENT_SCHEDULED:
            if not referral.healthcare_pro_id:
                referral.healthcare_pro_id = current_user.id
    
    db.commit()
    db.refresh(referral)
    return referral

# ==================== DASHBOARD ENDPOINTS ====================

@app.get("/dashboard/chw")
def chw_dashboard(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    from sqlalchemy import text
    
    total_mothers = db.query(Mother).filter(Mother.created_by_chw_id == current_user.id).count()
    high_risk = db.query(Mother).filter(
        Mother.created_by_chw_id == current_user.id,
        Mother.current_risk_level == "High"
    ).count()
    medium_risk = db.query(Mother).filter(
        Mother.created_by_chw_id == current_user.id,
        or_(Mother.current_risk_level == "Medium", Mother.current_risk_level == "Mid")
    ).count()
    low_risk = db.query(Mother).filter(
        Mother.created_by_chw_id == current_user.id,
        Mother.current_risk_level == "Low"
    ).count()
    
    today = datetime.utcnow().date()
    visits_due_today = db.query(Visit).filter(
        Visit.chw_id == current_user.id,
        func.date(Visit.next_visit_date) == today
    ).count()
    
    overdue_visits = db.query(Visit).filter(
        Visit.chw_id == current_user.id,
        Visit.next_visit_date < datetime.utcnow(),
        Visit.completed == False
    ).count()
    
    active_referrals = db.query(Referral).filter(
        Referral.chw_id == current_user.id,
        Referral.status != ReferralStatus.COMPLETED
    ).count()
    
    scheduled_appointments = db.execute(
        text("""
            SELECT COUNT(DISTINCT r.id) 
            FROM referrals r 
            WHERE r.chw_id = :chw_id 
            AND (r.status = 'APPOINTMENT_SCHEDULED' OR r.status = 'Appointment Scheduled')
        """),
        {"chw_id": current_user.id}
    ).scalar()
    
    # Performance Metrics
    total_visits = db.query(Visit).filter(Visit.chw_id == current_user.id).count()
    completed_visits = db.query(Visit).filter(
        Visit.chw_id == current_user.id,
        Visit.completed == True
    ).count()
    missed_visits = total_visits - completed_visits
    
    # Referral response time (average hours)
    referrals = db.query(Referral).filter(
        Referral.chw_id == current_user.id,
        Referral.hospital_received_time.isnot(None)
    ).all()
    avg_response_time = 0
    if referrals:
        total_hours = sum([(r.hospital_received_time - r.created_at).total_seconds() / 3600 for r in referrals])
        avg_response_time = total_hours / len(referrals)
    
    # Performance badge calculation
    score = 0
    if total_visits > 0:
        completion_rate = (completed_visits / total_visits) * 100
        if completion_rate >= 90:
            score += 30
        elif completion_rate >= 75:
            score += 20
        elif completion_rate >= 60:
            score += 10
    
    if high_risk > 0 and active_referrals == 0:
        score += 30  # All high-risk cases referred
    elif high_risk > 0:
        referral_rate = (active_referrals / high_risk) * 100
        if referral_rate >= 80:
            score += 20
        elif referral_rate >= 50:
            score += 10
    
    if avg_response_time > 0:
        if avg_response_time <= 24:
            score += 40
        elif avg_response_time <= 48:
            score += 25
        elif avg_response_time <= 72:
            score += 15
    
    badge = "Bronze"
    if score >= 80:
        badge = "Gold"
    elif score >= 50:
        badge = "Silver"
    
    # Upcoming due dates (next 7 days)
    seven_days_from_now = datetime.utcnow() + timedelta(days=7)
    upcoming_due_dates = db.query(Mother).filter(
        Mother.created_by_chw_id == current_user.id,
        Mother.due_date >= datetime.utcnow(),
        Mother.due_date <= seven_days_from_now
    ).count()
    
    return {
        "total_mothers": total_mothers,
        "low_risk_cases": low_risk,
        "mid_risk_cases": medium_risk,
        "high_risk_cases": high_risk,
        "upcoming_due_dates": upcoming_due_dates,
        "active_referrals": active_referrals,
        "scheduled_appointments": scheduled_appointments,
        "visits_due_today": visits_due_today,
        "overdue_visits": overdue_visits,
        "performance": {
            "visits_completed": completed_visits,
            "missed_visits": missed_visits,
            "referral_response_time_hours": round(avg_response_time, 1),
            "performance_score": score,
            "badge": badge
        }
    }

@app.get("/dashboard/healthcare-pro")
def healthcare_pro_dashboard(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    from sqlalchemy import text
    
    # Total referrals received at this facility
    total_referrals = db.execute(
        text("SELECT COUNT(*) FROM referrals WHERE hospital LIKE :facility"),
        {"facility": f"%{current_user.facility}%"}
    ).scalar()
    
    # Pending referrals
    pending_referrals = db.execute(
        text("SELECT COUNT(*) FROM referrals WHERE hospital LIKE :facility AND status LIKE '%Pending%'"),
        {"facility": f"%{current_user.facility}%"}
    ).scalar()
    
    # Emergency cases
    emergency_cases = db.execute(
        text("SELECT COUNT(*) FROM referrals WHERE hospital LIKE :facility AND status = 'Emergency Care Required'"),
        {"facility": f"%{current_user.facility}%"}
    ).scalar()
    
    # Scheduled appointments
    scheduled_appointments = db.execute(
        text("""
            SELECT COUNT(*) FROM referrals 
            WHERE hospital LIKE :facility 
            AND (status = 'APPOINTMENT_SCHEDULED' OR status = 'Appointment Scheduled')
        """),
        {"facility": f"%{current_user.facility}%"}
    ).scalar()
    
    # Completed cases
    completed_cases = db.execute(
        text("SELECT COUNT(*) FROM referrals WHERE hospital LIKE :facility AND status = 'Completed'"),
        {"facility": f"%{current_user.facility}%"}
    ).scalar()
    
    print(f"📊 Healthcare Pro Dashboard for {current_user.facility}:")
    print(f"   Total: {total_referrals}, Pending: {pending_referrals}, Emergency: {emergency_cases}")
    print(f"   Scheduled: {scheduled_appointments}, Completed: {completed_cases}")
    
    return {
        "total_referrals": total_referrals,
        "pending_referrals": pending_referrals,
        "emergency_cases": emergency_cases,
        "scheduled_appointments": scheduled_appointments,
        "completed_cases": completed_cases,
        "avg_response_time": "0h"
    }

# ==================== PREDICTION ENDPOINT ====================

def get_feature_importance_explanation(input_data, feature_importances):
    """Generate explanation of factors influencing the prediction"""
    feature_names = ["Age", "SystolicBP", "DiastolicBP", "BS", "BodyTemp", "HeartRate"]
    
    # Combine features with their importance scores
    feature_impact = list(zip(feature_names, feature_importances, 
                             [input_data["Age"], input_data["SystolicBP"], input_data["DiastolicBP"], 
                              input_data["BS"], input_data["BodyTemp"], input_data["HeartRate"]]))
    
    # Sort by importance (descending)
    feature_impact.sort(key=lambda x: x[1], reverse=True)
    
    explanations = []
    risk_factors = []
    
    for feature, importance, value in feature_impact:
        impact_level = "High" if importance > 0.2 else "Medium" if importance > 0.1 else "Low"
        
        if feature == "Age":
            if value < 18:
                risk_factors.append(f"Young maternal age ({value} years) - {impact_level} impact")
                explanations.append(f"Age {value}: Young mothers face higher pregnancy risks")
            elif value > 35:
                risk_factors.append(f"Advanced maternal age ({value} years) - {impact_level} impact")
                explanations.append(f"Age {value}: Advanced maternal age increases complications risk")
            else:
                explanations.append(f"Age {value}: Within optimal range (18-35 years)")
                
        elif feature == "SystolicBP":
            if value >= 140:
                risk_factors.append(f"High systolic BP ({value} mmHg) - {impact_level} impact")
                explanations.append(f"Systolic BP {value}: Indicates hypertension (≥140 mmHg)")
            elif value >= 120:
                risk_factors.append(f"Elevated systolic BP ({value} mmHg) - {impact_level} impact")
                explanations.append(f"Systolic BP {value}: Pre-hypertensive range (120-139 mmHg)")
            else:
                explanations.append(f"Systolic BP {value}: Normal range (<120 mmHg)")
                
        elif feature == "DiastolicBP":
            if value >= 90:
                risk_factors.append(f"High diastolic BP ({value} mmHg) - {impact_level} impact")
                explanations.append(f"Diastolic BP {value}: Indicates hypertension (≥90 mmHg)")
            elif value >= 80:
                risk_factors.append(f"Elevated diastolic BP ({value} mmHg) - {impact_level} impact")
                explanations.append(f"Diastolic BP {value}: Pre-hypertensive range (80-89 mmHg)")
            else:
                explanations.append(f"Diastolic BP {value}: Normal range (<80 mmHg)")
                
        elif feature == "BS":
            if value >= 7.8:
                risk_factors.append(f"High blood sugar ({value} mmol/L) - {impact_level} impact")
                explanations.append(f"Blood Sugar {value}: Indicates diabetes (≥7.8 mmol/L)")
            elif value >= 6.1:
                risk_factors.append(f"Elevated blood sugar ({value} mmol/L) - {impact_level} impact")
                explanations.append(f"Blood Sugar {value}: Pre-diabetic range (6.1-7.7 mmol/L)")
            else:
                explanations.append(f"Blood Sugar {value}: Normal range (<6.1 mmol/L)")
                
        elif feature == "BodyTemp":
            if value >= 38.0:
                risk_factors.append(f"Fever ({value}°C) - {impact_level} impact")
                explanations.append(f"Body Temperature {value}°C: Fever detected (≥38°C)")
            elif value >= 37.5:
                risk_factors.append(f"Elevated temperature ({value}°C) - {impact_level} impact")
                explanations.append(f"Body Temperature {value}°C: Slightly elevated (37.5-37.9°C)")
            else:
                explanations.append(f"Body Temperature {value}°C: Normal range (36-37.4°C)")
                
        elif feature == "HeartRate":
            if value >= 120:
                risk_factors.append(f"High heart rate ({value} bpm) - {impact_level} impact")
                explanations.append(f"Heart Rate {value}: Tachycardia (≥120 bpm)")
            elif value >= 100:
                risk_factors.append(f"Elevated heart rate ({value} bpm) - {impact_level} impact")
                explanations.append(f"Heart Rate {value}: Elevated (100-119 bpm)")
            elif value <= 60:
                risk_factors.append(f"Low heart rate ({value} bpm) - {impact_level} impact")
                explanations.append(f"Heart Rate {value}: Bradycardia (≤60 bpm)")
            else:
                explanations.append(f"Heart Rate {value}: Normal range (60-99 bpm)")
    
    return {
        "detailed_explanations": explanations,
        "risk_factors": risk_factors,
        "most_influential_factors": [f"{name} ({importance:.1%} influence)" for name, importance, _ in feature_impact[:3]]
    }

@app.post("/predict")
def predict(data: PregnancyInput):
    if rf_model is None or scaler is None or label_encoder is None:
        return {
            "error": True,
            "message": "We are currently unable to generate a prediction. Please try again later or consult a healthcare professional."
        }
    
    try:
        input_data = {
            "Age": data.Age,
            "SystolicBP": data.SystolicBP,
            "DiastolicBP": data.DiastolicBP,
            "BS": data.BS,
            "BodyTemp": data.BodyTemp,
            "HeartRate": data.HeartRate
        }
        
        input_df = pd.DataFrame([input_data])
        
        scaled_input = scaler.transform(input_df)
        prediction = rf_model.predict(scaled_input)[0]
        probabilities = rf_model.predict_proba(scaled_input)[0]
        confidence_percentage = max(probabilities) * 100
        risk_level = label_encoder.inverse_transform([prediction])[0]
        
        # Get feature importances from the model
        feature_importances = rf_model.feature_importances_
        
        # Generate detailed explanation
        explanation = get_feature_importance_explanation(input_data, feature_importances)
        
        # Normalize risk level to match project.md (Low/Medium/High)
        risk_str = str(risk_level)
        if 'mid' in risk_str.lower():
            risk_str = 'Medium'
        elif 'low' in risk_str.lower():
            risk_str = 'Low'
        elif 'high' in risk_str.lower():
            risk_str = 'High'
        
        return {
            "error": False,
            "risk_level": risk_str,
            "confidence": round(confidence_percentage, 2),
            "explanation": explanation
        }
    except Exception as e:
        print(f"Prediction error: {e}")
        return {
            "error": True,
            "message": "We are currently unable to generate a prediction. Please try again later or consult a healthcare professional."
        }

@app.post("/predict-with-referral")
def predict_with_referral(data: PregnancyInput, mother_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Predict risk and automatically generate referral recommendation for HIGH risk cases"""
    if rf_model is None or scaler is None or label_encoder is None:
        return {
            "error": True,
            "message": "We are currently unable to generate a prediction. Please try again later or consult a healthcare professional."
        }
    
    try:
        # Run prediction
        input_data = {
            "Age": data.Age,
            "SystolicBP": data.SystolicBP,
            "DiastolicBP": data.DiastolicBP,
            "BS": data.BS,
            "BodyTemp": data.BodyTemp,
            "HeartRate": data.HeartRate
        }
        
        input_df = pd.DataFrame([input_data])
        
        scaled_input = scaler.transform(input_df)
        prediction = rf_model.predict(scaled_input)[0]
        probabilities = rf_model.predict_proba(scaled_input)[0]
        confidence_percentage = max(probabilities) * 100
        risk_level = label_encoder.inverse_transform([prediction])[0]
        
        # Get feature importances from the model
        feature_importances = rf_model.feature_importances_
        
        # Generate detailed explanation
        explanation = get_feature_importance_explanation(input_data, feature_importances)
        
        # Normalize risk level to match project.md (Low/Medium/High)
        risk_str = str(risk_level)
        if 'mid' in risk_str.lower():
            risk_str = 'Medium'
        elif 'low' in risk_str.lower():
            risk_str = 'Low'
        elif 'high' in risk_str.lower():
            risk_str = 'High'
        
        result = {
            "error": False,
            "risk_level": risk_str,
            "confidence": round(confidence_percentage, 2),
            "explanation": explanation
        }
        
        # If HIGH risk, calculate severity and recommend hospital
        if risk_str == "High":
            mother = db.query(Mother).filter(Mother.id == mother_id).first()
            if not mother:
                return {
                    "error": True,
                    "message": "We are currently unable to generate a prediction. Please try again later or consult a healthcare professional."
                }
            
            # Get referral recommendation
            health_data = {
                'systolic_bp': data.SystolicBP,
                'diastolic_bp': data.DiastolicBP,
                'blood_sugar': data.BS,
                'body_temp': data.BodyTemp,
                'heart_rate': data.HeartRate,
                'age': data.Age
            }
            
            mother_location = {
                'district': mother.district,
                'sector': mother.sector
            }
            
            mother_medical_history = {
                'has_chronic_condition': mother.has_chronic_condition,
                'on_medication': mother.on_medication,
                'has_allergies': mother.has_allergies
            }
            
            recommendation = get_referral_recommendation(health_data, mother_location, mother_medical_history)
            
            result['referral_required'] = True
            result['severity'] = recommendation['severity'].value
            result['recommended_hospital'] = recommendation['hospital']
            result['reasoning'] = recommendation['reasoning']
            result['severity_score'] = recommendation['score']
            result['critical_vitals'] = recommendation['critical_vitals']
            result['risk_detected_time'] = datetime.utcnow().isoformat()
        else:
            result['referral_required'] = False
        
        return result
    except Exception as e:
        print(f"Prediction with referral error: {e}")
        return {
            "error": True,
            "message": "We are currently unable to generate a prediction. Please try again later or consult a healthcare professional."
        }

@app.get("/")
def home():
    return {"message": "MamaSafe API v2.0", "status": "running"}

# ==================== CHAT ENDPOINTS ====================

# Import WebSocket manager
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
try:
    from websocket_manager import manager
except ImportError:
    # Create a simple manager if import fails
    class SimpleManager:
        def __init__(self):
            self.active_connections = {}
        async def connect(self, websocket, chat_room_id, user_id, user_name):
            await websocket.accept()
        def disconnect(self, websocket):
            pass
        async def send_message_to_room(self, chat_room_id, sender_websocket, message_data):
            pass
    manager = SimpleManager()

@app.post("/chat/rooms", response_model=ChatRoomResponse)
def create_chat_room(chat_data: ChatRoomCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Create a chat room for high-risk mother referral"""
    
    print(f"🔍 CREATE CHAT ROOM DEBUG:")
    print(f"   User: {current_user.name} ({current_user.role.value})")
    print(f"   User facility: '{current_user.facility}'")
    print(f"   Referral ID: {chat_data.referral_id}")
    print(f"   Mother ID: {chat_data.mother_id}")
    
    try:
        # Verify the referral exists (use raw SQL to avoid enum issues)
        from sqlalchemy import text
        referral_result = db.execute(
            text("""
                SELECT id, mother_id, chw_id, hospital, severity, status, notes
                FROM referrals 
                WHERE id = :referral_id
                LIMIT 1
            """),
            {"referral_id": chat_data.referral_id}
        ).fetchone()
        
        if not referral_result:
            print(f"❌ Referral {chat_data.referral_id} not found")
            raise HTTPException(status_code=404, detail="Referral not found")
        
        print(f"✅ Referral found:")
        print(f"   Hospital: '{referral_result[3]}'")
        print(f"   CHW ID: {referral_result[2]}")
        print(f"   Status: {referral_result[5]}")
        
        # Check access permissions based on user role
        if current_user.role == UserRole.CHW:
            # CHW can only access referrals they created
            if referral_result[2] != current_user.id:  # chw_id
                print(f"❌ CHW access denied: referral CHW ID {referral_result[2]} != current user ID {current_user.id}")
                raise HTTPException(status_code=403, detail="Access denied to this referral")
            print(f"✅ CHW access granted")
        elif current_user.role == UserRole.HEALTHCARE_PRO:
            # Healthcare professional can access referrals for their hospital (more flexible matching)
            hospital_name = referral_result[3] or ""  # hospital
            user_facility = current_user.facility or ""
            
            # Check if facility name is contained in hospital name or vice versa (case insensitive)
            facility_matches = (
                user_facility.lower() in hospital_name.lower() or 
                hospital_name.lower() in user_facility.lower() or
                user_facility.lower() == hospital_name.lower()
            )
            
            print(f"🏥 Hospital matching debug:")
            print(f"   User facility: '{user_facility}'")
            print(f"   Referral hospital: '{hospital_name}'")
            print(f"   Matches: {facility_matches}")
            
            if not facility_matches:
                print(f"❌ Healthcare pro access denied: facility mismatch")
                raise HTTPException(status_code=403, detail=f"Access denied - facility mismatch: '{user_facility}' vs '{hospital_name}'")
            print(f"✅ Healthcare pro access granted")
        
        # Verify the mother exists
        mother = db.query(Mother).filter(Mother.id == chat_data.mother_id).first()
        if not mother:
            print(f"❌ Mother {chat_data.mother_id} not found")
            raise HTTPException(status_code=404, detail="Mother not found")
        
        print(f"✅ Mother found: {mother.name} (Risk: {mother.current_risk_level})")
        
        # Allow chat for high-risk mothers OR mothers with referrals
        if mother.current_risk_level != "High" and not referral_result:
            print(f"❌ Chat not allowed: mother is not high risk and no referral")
            raise HTTPException(status_code=400, detail="Chat only available for high-risk mothers or mothers with referrals")
        
        # Check if chat room already exists (use raw SQL to avoid enum issues)
        existing_room_result = db.execute(
            text("""
                SELECT id, mother_id, referral_id, chw_id, healthcare_pro_id, 
                       hospital_name, is_active, created_at, last_message_at
                FROM chat_rooms 
                WHERE mother_id = :mother_id 
                AND referral_id = :referral_id 
                AND is_active = 1
                LIMIT 1
            """),
            {"mother_id": chat_data.mother_id, "referral_id": chat_data.referral_id}
        ).fetchone()
        
        if existing_room_result:
            print(f"✅ Existing chat room found: {existing_room_result[0]}")
            # Return existing room with additional info
            unread_count = db.execute(
                text("""
                    SELECT COUNT(*) FROM chat_messages 
                    WHERE chat_room_id = :room_id 
                    AND sender_id != :user_id 
                    AND is_read = 0
                """),
                {"room_id": existing_room_result[0], "user_id": current_user.id}
            ).scalar()
            
            return {
                "id": existing_room_result[0],
                "mother_id": existing_room_result[1],
                "referral_id": existing_room_result[2],
                "chw_id": existing_room_result[3],
                "healthcare_pro_id": existing_room_result[4],
                "hospital_name": existing_room_result[5],
                "is_active": existing_room_result[6],
                "created_at": existing_room_result[7],
                "last_message_at": existing_room_result[8],
                "mother_name": mother.name,
                "mother_risk_level": mother.current_risk_level,
                "unread_count": unread_count or 0
            }
        
        # Create new chat room
        # CHWs can always create new rooms
        # Healthcare professionals can create rooms if none exists for their referrals
        if current_user.role == UserRole.CHW:
            print(f"📝 CHW creating new chat room...")
        elif current_user.role == UserRole.HEALTHCARE_PRO:
            print(f"📝 Healthcare professional creating new chat room...")
        else:
            print(f"❌ User role {current_user.role.value} cannot create chat rooms")
            raise HTTPException(status_code=403, detail="Only CHWs and Healthcare Professionals can create chat rooms")
        
        print(f"📝 Creating new chat room...")
        chat_room = ChatRoom(
            mother_id=chat_data.mother_id,
            referral_id=chat_data.referral_id,
            chw_id=current_user.id if current_user.role == UserRole.CHW else referral_result[2],  # Use referral's CHW ID if healthcare pro
            healthcare_pro_id=current_user.id if current_user.role == UserRole.HEALTHCARE_PRO else None,
            hospital_name=referral_result[3] if referral_result[3] else "Unknown Hospital"
        )
        
        db.add(chat_room)
        db.commit()
        db.refresh(chat_room)
        
        print(f"✅ Chat room created: {chat_room.id}")
        
        return {
            "id": chat_room.id,
            "mother_id": chat_room.mother_id,
            "referral_id": chat_room.referral_id,
            "chw_id": chat_room.chw_id,
            "healthcare_pro_id": chat_room.healthcare_pro_id,
            "hospital_name": chat_room.hospital_name,
            "is_active": chat_room.is_active,
            "created_at": chat_room.created_at,
            "last_message_at": chat_room.last_message_at,
            "mother_name": mother.name,
            "mother_risk_level": mother.current_risk_level,
            "unread_count": 0
        }
        
    except HTTPException:
        # Re-raise HTTP exceptions as-is
        raise
    except Exception as e:
        print(f"❌ Unexpected error in create_chat_room: {e}")
        print(f"   Error type: {type(e)}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/debug/chat-rooms")
def debug_all_chat_rooms(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Debug endpoint to see all chat rooms"""
    from sqlalchemy import text
    
    # Get all chat rooms with details
    rooms_raw = db.execute(
        text("""
            SELECT cr.id, cr.mother_id, cr.referral_id, cr.chw_id, cr.healthcare_pro_id,
                   cr.hospital_name, cr.is_active, cr.created_at, cr.last_message_at,
                   m.name as mother_name,
                   chw.name as chw_name,
                   hp.name as hp_name
            FROM chat_rooms cr
            LEFT JOIN mothers m ON cr.mother_id = m.id
            LEFT JOIN users chw ON cr.chw_id = chw.id
            LEFT JOIN users hp ON cr.healthcare_pro_id = hp.id
            ORDER BY cr.created_at DESC
        """)
    ).fetchall()
    
    result = []
    for room in rooms_raw:
        # Count messages in this room
        message_count = db.execute(
            text("SELECT COUNT(*) FROM chat_messages WHERE chat_room_id = :room_id"),
            {"room_id": room[0]}
        ).scalar()
        
        result.append({
            "id": room[0],
            "mother_id": room[1],
            "referral_id": room[2],
            "chw_id": room[3],
            "healthcare_pro_id": room[4],
            "hospital_name": room[5],
            "is_active": room[6],
            "created_at": room[7],
            "last_message_at": room[8],
            "mother_name": room[9],
            "chw_name": room[10],
            "hp_name": room[11],
            "message_count": message_count,
            "current_user_id": current_user.id,
            "current_user_role": current_user.role.value,
            "user_can_access": (
                (current_user.role == UserRole.CHW and room[3] == current_user.id) or
                (current_user.role == UserRole.HEALTHCARE_PRO and current_user.facility and room[5] and 
                 (current_user.facility.lower() in room[5].lower() or room[5].lower() in current_user.facility.lower()))
            )
        })
    
    return {
        "current_user": {
            "id": current_user.id,
            "name": current_user.name,
            "role": current_user.role.value,
            "facility": current_user.facility
        },
        "chat_rooms": result
    }

@app.get("/chat/rooms", response_model=list[ChatRoomResponse])
def get_chat_rooms(db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Get all chat rooms for current user"""
    
    print(f"🏠 GET CHAT ROOMS DEBUG:")
    print(f"   User: {current_user.name} ({current_user.role.value})")
    print(f"   User ID: {current_user.id}")
    print(f"   User facility: '{current_user.facility}'")
    
    if current_user.role == UserRole.CHW:
        # CHW sees rooms where they are the CHW (either created by them or assigned to them)
        rooms = db.query(ChatRoom).filter(
            ChatRoom.chw_id == current_user.id,
            ChatRoom.is_active == True
        ).order_by(ChatRoom.last_message_at.desc()).all()
        print(f"📋 CHW found {len(rooms)} chat rooms")
    else:
        # Healthcare professionals see rooms for their hospital (more flexible matching)
        user_facility = current_user.facility or ""
        
        # Get all rooms and filter by hospital name matching
        all_rooms = db.query(ChatRoom).filter(ChatRoom.is_active == True).all()
        rooms = []
        
        print(f"📋 Checking {len(all_rooms)} total rooms for facility matching")
        
        for room in all_rooms:
            hospital_name = room.hospital_name or ""
            facility_matches = (
                user_facility.lower() in hospital_name.lower() or 
                hospital_name.lower() in user_facility.lower() or
                user_facility.lower() == hospital_name.lower()
            )
            
            print(f"   Room {room.id}: '{hospital_name}' vs '{user_facility}' = {facility_matches}")
            
            if facility_matches:
                rooms.append(room)
        
        print(f"📋 Healthcare pro found {len(rooms)} matching chat rooms")
        
        # Sort by last message time
        rooms.sort(key=lambda x: x.last_message_at or x.created_at, reverse=True)
    
    result = []
    for room in rooms:
        mother = db.query(Mother).filter(Mother.id == room.mother_id).first()
        unread_count = db.query(ChatMessage).filter(
            ChatMessage.chat_room_id == room.id,
            ChatMessage.sender_id != current_user.id,
            ChatMessage.is_read == False
        ).count()
        
        print(f"   Room {room.id}: Mother {mother.name if mother else 'Unknown'}, Unread: {unread_count}")
        
        result.append({
            **room.__dict__,
            "mother_name": mother.name if mother else "Unknown",
            "mother_risk_level": mother.current_risk_level if mother else "Unknown",
            "unread_count": unread_count
        })
    
    print(f"✅ Returning {len(result)} chat rooms")
    return result

@app.get("/chat/rooms/{room_id}/messages", response_model=list[ChatMessageResponse])
def get_chat_messages(room_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Get messages for a chat room"""
    
    print(f"💬 GET CHAT MESSAGES DEBUG:")
    print(f"   Room ID: {room_id}")
    print(f"   User: {current_user.name} ({current_user.role.value})")
    print(f"   User ID: {current_user.id}")
    
    # Verify user has access to this chat room
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        print(f"❌ Chat room {room_id} not found")
        raise HTTPException(status_code=404, detail="Chat room not found")
    
    print(f"✅ Chat room found:")
    print(f"   CHW ID: {room.chw_id}")
    print(f"   Healthcare Pro ID: {room.healthcare_pro_id}")
    print(f"   Hospital: {room.hospital_name}")
    
    # Check access permissions
    has_access = False
    if current_user.role == UserRole.CHW and room.chw_id == current_user.id:
        has_access = True
        print(f"✅ CHW access granted (room CHW matches user)")
    elif current_user.role == UserRole.HEALTHCARE_PRO:
        # More flexible hospital name matching
        hospital_name = room.hospital_name or ""
        user_facility = current_user.facility or ""
        
        facility_matches = (
            user_facility.lower() in hospital_name.lower() or 
            hospital_name.lower() in user_facility.lower() or
            user_facility.lower() == hospital_name.lower()
        )
        
        print(f"🏥 Chat room access debug:")
        print(f"   User facility: '{user_facility}'")
        print(f"   Room hospital: '{hospital_name}'")
        print(f"   Matches: {facility_matches}")
        
        has_access = facility_matches
        if has_access:
            print(f"✅ Healthcare pro access granted")
    
    if not has_access:
        print(f"❌ Access denied to chat room {room_id}")
        raise HTTPException(status_code=403, detail="Access denied to this chat room")
    
    # Get messages
    messages = db.query(ChatMessage).filter(
        ChatMessage.chat_room_id == room_id
    ).order_by(ChatMessage.created_at.asc()).all()
    
    print(f"💬 Found {len(messages)} messages in room {room_id}")
    
    # Mark messages as read for current user
    unread_messages = db.query(ChatMessage).filter(
        ChatMessage.chat_room_id == room_id,
        ChatMessage.sender_id != current_user.id,
        ChatMessage.is_read == False
    ).all()
    
    print(f"💬 Marking {len(unread_messages)} messages as read")
    
    for msg in unread_messages:
        msg.is_read = True
    db.commit()
    
    # Build response with sender info and is_from_current_user flag
    result = []
    for message in messages:
        sender = db.query(User).filter(User.id == message.sender_id).first()
        result.append({
            "id": message.id,
            "chat_room_id": message.chat_room_id,
            "sender_id": message.sender_id,
            "message": message.message,
            "message_type": message.message_type,
            "is_read": message.is_read,
            "created_at": message.created_at,
            "sender_name": sender.name if sender else "Unknown",
            "sender_role": sender.role.value if sender else "Unknown",
            "is_from_current_user": message.sender_id == current_user.id
        })
    
    print(f"✅ Returning {len(result)} messages")
    return result

@app.post("/chat/rooms/{room_id}/messages", response_model=ChatMessageResponse)
def send_chat_message(room_id: int, message_data: ChatMessageCreate, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Send a message to chat room"""
    
    # Verify user has access to this chat room
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Chat room not found")
    
    # Check access permissions
    has_access = False
    if current_user.role == UserRole.CHW and room.chw_id == current_user.id:
        has_access = True
    elif current_user.role == UserRole.HEALTHCARE_PRO:
        # More flexible hospital name matching
        hospital_name = room.hospital_name or ""
        user_facility = current_user.facility or ""
        
        facility_matches = (
            user_facility.lower() in hospital_name.lower() or 
            hospital_name.lower() in user_facility.lower() or
            user_facility.lower() == hospital_name.lower()
        )
        
        print(f"💬 Send message access debug:")
        print(f"   User facility: '{user_facility}'")
        print(f"   Room hospital: '{hospital_name}'")
        print(f"   Matches: {facility_matches}")
        
        has_access = facility_matches
        
        # Assign healthcare professional to room if not already assigned
        if has_access and not room.healthcare_pro_id:
            room.healthcare_pro_id = current_user.id
    
    if not has_access:
        raise HTTPException(status_code=403, detail="Access denied to this chat room")
    
    # Create message
    message = ChatMessage(
        chat_room_id=room_id,
        sender_id=current_user.id,
        message=message_data.message,
        message_type=message_data.message_type
    )
    
    db.add(message)
    
    # Update room last message time
    room.last_message_at = datetime.utcnow()
    
    db.commit()
    db.refresh(message)
    
    return {
        "id": message.id,
        "chat_room_id": message.chat_room_id,
        "sender_id": message.sender_id,
        "message": message.message,
        "message_type": message.message_type,
        "is_read": message.is_read,
        "created_at": message.created_at,
        "sender_name": current_user.name,
        "sender_role": current_user.role.value,
        "is_from_current_user": True
    }

@app.websocket("/ws/chat/{room_id}")
async def websocket_chat_endpoint(websocket: WebSocket, room_id: int, token: str, db: Session = Depends(get_db)):
    """WebSocket endpoint for real-time chat"""
    
    try:
        # Verify token and get user (simplified - in production use proper JWT verification)
        # For now, we'll accept the connection and handle auth in the frontend
        
        # Get user info from token (simplified)
        user_id = 1  # This should be extracted from JWT token
        user_name = "User"  # This should be extracted from JWT token
        
        await manager.connect(websocket, room_id, user_id, user_name)
        
        while True:
            # Receive message from WebSocket
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Send message to all users in the room
            await manager.send_message_to_room(room_id, websocket, message_data)
            
    except WebSocketDisconnect:
        manager.disconnect(websocket)


@app.get("/debug/chat-access/{referral_id}")
def debug_chat_access(referral_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_approved_user)):
    """Debug endpoint to check chat access issues"""
    from sqlalchemy import text
    
    # Get referral info
    referral_result = db.execute(
        text("""
            SELECT id, mother_id, chw_id, hospital, severity, status, notes
            FROM referrals 
            WHERE id = :referral_id
            LIMIT 1
        """),
        {"referral_id": referral_id}
    ).fetchone()
    
    if not referral_result:
        return {"error": "Referral not found"}
    
    # Get current user info
    user_info = {
        "id": current_user.id,
        "name": current_user.name,
        "role": current_user.role.value,
        "facility": current_user.facility if hasattr(current_user, 'facility') else None
    }
    
    # Get referral info
    referral_info = {
        "id": referral_result[0],
        "mother_id": referral_result[1],
        "chw_id": referral_result[2],
        "hospital": referral_result[3],
        "severity": referral_result[4],
        "status": referral_result[5]
    }
    
    # Check access logic
    access_check = {
        "is_chw": current_user.role == UserRole.CHW,
        "is_healthcare_pro": current_user.role == UserRole.HEALTHCARE_PRO,
        "chw_owns_referral": referral_result[2] == current_user.id if current_user.role == UserRole.CHW else False,
        "facility_matches": current_user.facility in referral_result[3] if current_user.role == UserRole.HEALTHCARE_PRO and current_user.facility else False,
        "facility_exact_match": current_user.facility == referral_result[3] if current_user.role == UserRole.HEALTHCARE_PRO and current_user.facility else False
    }
    
    # Check for existing chat room
    existing_room = db.execute(
        text("""
            SELECT id, hospital_name FROM chat_rooms 
            WHERE referral_id = :referral_id AND is_active = 1
            LIMIT 1
        """),
        {"referral_id": referral_id}
    ).fetchone()
    
    return {
        "user": user_info,
        "referral": referral_info,
        "access_check": access_check,
        "chat_room": {"id": existing_room[0], "hospital_name": existing_room[1]} if existing_room else None
    }

@app.get("/admin/referrals/all")
def get_all_referrals(db: Session = Depends(get_db), admin: User = Depends(get_admin_user)):
    """Get all referrals for admin - from all hospitals"""
    from sqlalchemy import text
    
    referrals_raw = db.execute(
        text("""
            SELECT r.id, r.mother_id, r.chw_id, r.healthcare_pro_id, r.hospital, 
                   r.severity, r.notes, r.diagnosis, r.treatment_notes, r.status,
                   r.risk_detected_time, r.chw_confirmed_time, r.hospital_received_time,
                   r.created_at, r.completed_at, r.appointment_date, r.appointment_time, r.department,
                   m.id as m_id, m.name as m_name, m.age as m_age, m.phone as m_phone,
                   m.current_risk_level, m.province, m.district, m.sector, m.cell, m.village,
                   m.has_allergies, m.has_chronic_condition, m.on_medication,
                   c.id as c_id, c.name as c_name, c.phone as c_phone
            FROM referrals r
            LEFT JOIN mothers m ON r.mother_id = m.id
            LEFT JOIN users c ON r.chw_id = c.id
            ORDER BY r.created_at DESC
        """)
    ).fetchall()
    
    result = []
    for ref in referrals_raw:
        ref_dict = {
            "id": ref[0],
            "mother_id": ref[1],
            "chw_id": ref[2],
            "healthcare_pro_id": ref[3],
            "hospital": ref[4],
            "severity": ref[5],
            "notes": ref[6],
            "diagnosis": ref[7],
            "treatment_notes": ref[8],
            "status": ref[9],
            "risk_detected_time": ref[10],
            "chw_confirmed_time": ref[11],
            "hospital_received_time": ref[12],
            "created_at": ref[13],
            "completed_at": ref[14],
            "appointment_date": ref[15],
            "appointment_time": ref[16],
            "department": ref[17],
            "mother": {
                "id": ref[18],
                "name": ref[19],
                "age": ref[20],
                "phone": ref[21],
                "risk_level": ref[22],
                "province": ref[23],
                "district": ref[24],
                "sector": ref[25],
                "cell": ref[26],
                "village": ref[27],
                "has_allergies": ref[28],
                "has_chronic_condition": ref[29],
                "on_medication": ref[30],
            } if ref[18] else None,
            "chw": {
                "id": ref[31],
                "name": ref[32],
                "phone": ref[33],
            } if ref[31] else None
        }
        result.append(ref_dict)
    
    return result
