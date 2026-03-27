from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class ChatRoom(Base):
    __tablename__ = "chat_rooms"
    
    id = Column(Integer, primary_key=True, index=True)
    mother_id = Column(Integer, ForeignKey("mothers.id"), nullable=False)
    referral_id = Column(Integer, ForeignKey("referrals.id"), nullable=False)
    chw_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    healthcare_pro_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    hospital_name = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_message_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    mother = relationship("Mother", foreign_keys=[mother_id])
    referral = relationship("Referral", foreign_keys=[referral_id])
    chw = relationship("User", foreign_keys=[chw_id])
    healthcare_pro = relationship("User", foreign_keys=[healthcare_pro_id])
    messages = relationship("ChatMessage", back_populates="chat_room", cascade="all, delete-orphan")

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    chat_room_id = Column(Integer, ForeignKey("chat_rooms.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    message = Column(Text, nullable=False)
    message_type = Column(String, default="text")  # text, image, file
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    chat_room = relationship("ChatRoom", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])