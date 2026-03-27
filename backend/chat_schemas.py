from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

# Chat Room Schemas
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

# Chat Message Schemas
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
    
    class Config:
        from_attributes = True

# WebSocket Message Schema
class WebSocketMessage(BaseModel):
    type: str  # "message", "typing", "join", "leave"
    chat_room_id: int
    message: Optional[str] = None
    sender_id: Optional[int] = None
    sender_name: Optional[str] = None