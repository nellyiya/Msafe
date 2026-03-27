from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum

# Enums
class UserRole(str, Enum):
    CHW = "CHW"
    HEALTHCARE_PRO = "HealthcarePro"
    ADMIN = "Admin"

class UserStatus(str, Enum):
    PENDING = "Pending"
    ACTIVE = "Active"
    SUSPENDED = "Suspended"

class ReferralStatus(str, Enum):
    PENDING = "PENDING"
    RECEIVED = "RECEIVED"
    APPOINTMENT_SCHEDULED = "APPOINTMENT_SCHEDULED"
    COMPLETED = "COMPLETED"
    EMERGENCY_CARE_REQUIRED = "EMERGENCY_CARE_REQUIRED"

class SeverityLevel(str, Enum):
    LOW = "LOW"
    MEDIUM = "MEDIUM"
    HIGH = "HIGH"
    CRITICAL = "CRITICAL"

# User schemas
class UserRegister(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str
    role: UserRole
    district: Optional[str] = None
    sector: Optional[str] = None
    cell: Optional[str] = None
    village: Optional[str] = None
    facility: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: str
    role: UserRole
    district: Optional[str] = None
    sector: Optional[str] = None
    cell: Optional[str] = None
    village: Optional[str] = None
    facility: Optional[str] = None
    is_approved: bool
    status: Optional[UserStatus] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

# Mother schemas
class MotherCreate(BaseModel):
    name: str
    age: int
    phone: str
    province: str
    district: str
    sector: str
    cell: str
    village: str
    pregnancy_start_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    has_allergies: Optional[bool] = False
    has_chronic_condition: Optional[bool] = False
    on_medication: Optional[bool] = False

class MotherResponse(BaseModel):
    id: int
    name: str
    age: int
    phone: str
    province: str
    district: str
    sector: str
    cell: str
    village: str
    pregnancy_start_date: Optional[datetime] = None
    due_date: Optional[datetime] = None
    created_by_chw_id: int
    current_risk_level: Optional[str] = None
    has_allergies: Optional[bool] = False
    has_chronic_condition: Optional[bool] = False
    on_medication: Optional[bool] = False
    created_at: Optional[datetime] = None
    hasScheduledAppointment: Optional[bool] = False

    class Config:
        from_attributes = True

# Health Record schemas
class HealthRecordCreate(BaseModel):
    mother_id: int
    systolic_bp: float
    diastolic_bp: float
    blood_sugar: float
    body_temp: float
    heart_rate: float
    risk_level: str
    notes: Optional[str] = None

class HealthRecordResponse(BaseModel):
    id: int
    mother_id: int
    systolic_bp: float
    diastolic_bp: float
    blood_sugar: float
    body_temp: float
    heart_rate: float
    risk_level: str
    notes: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Visit schemas
class VisitCreate(BaseModel):
    mother_id: int
    visit_type: str
    notes: Optional[str] = None
    next_visit_date: Optional[datetime] = None
    completed: bool = False

class VisitResponse(BaseModel):
    id: int
    mother_id: int
    chw_id: int
    visit_type: str
    notes: Optional[str] = None
    next_visit_date: Optional[datetime] = None
    completed: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Referral schemas
class ReferralCreate(BaseModel):
    mother_id: int
    hospital: str
    severity: str
    notes: Optional[str] = None
    risk_detected_time: Optional[datetime] = None

class ReferralUpdate(BaseModel):
    healthcare_pro_id: Optional[int] = None
    diagnosis: Optional[str] = None
    treatment_notes: Optional[str] = None
    status: Optional[ReferralStatus] = None
    appointment_date: Optional[datetime] = None
    appointment_time: Optional[str] = None
    department: Optional[str] = None
    hospital_received_time: Optional[datetime] = None

class ReferralResponse(BaseModel):
    id: int
    mother_id: int
    chw_id: int
    healthcare_pro_id: Optional[int] = None
    hospital: str
    severity: str
    notes: Optional[str] = None
    diagnosis: Optional[str] = None
    treatment_notes: Optional[str] = None
    status: Optional[str] = None
    risk_detected_time: Optional[datetime] = None
    chw_confirmed_time: Optional[datetime] = None
    hospital_received_time: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    appointment_date: Optional[datetime] = None
    appointment_time: Optional[str] = None
    department: Optional[str] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

# Prediction schema
class PregnancyInput(BaseModel):
    Age: int
    SystolicBP: float
    DiastolicBP: float
    BS: float  # Blood Sugar
    BodyTemp: float
    HeartRate: float

# Chat Schemas
class ChatRoomCreate(BaseModel):
    mother_id: int
    referral_id: int

class ChatRoomResponse(BaseModel):
    id: int
    mother_id: int
    referral_id: int
    chw_id: int
    healthcare_pro_id: Optional[int] = None
    hospital_name: str
    is_active: bool
    created_at: datetime
    last_message_at: datetime
    
    # Mother info for context
    mother_name: Optional[str] = None
    mother_risk_level: Optional[str] = None
    
    # Unread message count
    unread_count: Optional[int] = 0
    
    class Config:
        from_attributes = True

class ChatMessageCreate(BaseModel):
    message: str
    message_type: str = "text"

class ChatMessageResponse(BaseModel):
    id: int
    chat_room_id: int
    sender_id: int
    message: str
    message_type: str
    is_read: bool
    created_at: datetime
    
    # Sender info
    sender_name: Optional[str] = None
    sender_role: Optional[str] = None
    
    # Current user identification
    is_from_current_user: Optional[bool] = False
    
    class Config:
        from_attributes = True