import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User
from passlib.context import CryptContext

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def debug_login(email, password):
    db = SessionLocal()
    
    print(f"🔍 Debugging login for: {email}")
    print(f"🔍 Password attempt: {password}")
    
    # Check if user exists
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print("❌ User not found in database")
        return
    
    print(f"✅ User found: {user.name}")
    print(f"📧 Email: {user.email}")
    print(f"👤 Role: {user.role}")
    print(f"✅ Approved: {user.is_approved}")
    print(f"📊 Status: {user.status}")
    print(f"🔐 Password hash: {user.password_hash[:50]}...")
    
    # Test password verification
    try:
        is_valid = pwd_context.verify(password, user.password_hash)
        print(f"🔐 Password verification result: {is_valid}")
        
        if is_valid:
            print("✅ Password is correct!")
        else:
            print("❌ Password is incorrect!")
            
            # Try to create a new hash and compare
            new_hash = pwd_context.hash(password)
            print(f"🔐 New hash would be: {new_hash[:50]}...")
            
    except Exception as e:
        print(f"❌ Error during password verification: {e}")
    
    # Check account status
    if not user.is_approved:
        print("⚠️  Account is not approved")
    
    if user.status.value == "PENDING":
        print("⚠️  Account status is PENDING")
    elif user.status.value == "SUSPENDED":
        print("⚠️  Account status is SUSPENDED")
    
    db.close()

if __name__ == "__main__":
    debug_login("uwimana@gmail.com", "password123")