import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User
from passlib.context import CryptContext

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def fix_user_password(email, new_password):
    db = SessionLocal()
    
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print(f"User {email} not found")
        return
    
    # Hash password using passlib (same as API)
    new_hash = pwd_context.hash(new_password)
    
    print(f"Updating password for {user.name} ({email})")
    print(f"Old hash: {user.password_hash[:50]}...")
    print(f"New hash: {new_hash[:50]}...")
    
    user.password_hash = new_hash
    db.commit()
    
    print("✅ Password updated successfully!")
    print(f"You can now login with:")
    print(f"Email: {email}")
    print(f"Password: {new_password}")
    
    db.close()

if __name__ == "__main__":
    # Fix the CHW user password
    fix_user_password("uwimana@gmail.com", "password123")