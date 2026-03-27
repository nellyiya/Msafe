import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User
from passlib.context import CryptContext

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def update_user_password(email, new_password):
    db = SessionLocal()
    
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print(f"User {email} not found")
        return False
    
    # Hash password using passlib (same as API)
    new_hash = pwd_context.hash(new_password)
    
    print(f"Updating password for: {user.name} ({email})")
    print(f"New password: {new_password}")
    
    user.password_hash = new_hash
    db.commit()
    
    print("Password updated successfully!")
    
    # Update both database files to keep them in sync
    print("Syncing to API database...")
    
    db.close()
    return True

def sync_databases():
    """Copy the main database to the API directory"""
    import shutil
    try:
        shutil.copy("mamasafe.db", "api/mamasafe.db")
        print("Database synced to API directory")
        return True
    except Exception as e:
        print(f"Error syncing database: {e}")
        return False

if __name__ == "__main__":
    print("UPDATING CHW SANDRINE UWIMANA PASSWORD")
    print("=" * 50)
    
    # Update Sandrine Uwimana's password
    if update_user_password("uwimana@gmail.com", "Uwimana 123"):
        # Sync databases
        sync_databases()
        
        print("\nPassword update completed!")
        print("=" * 50)
        print("UPDATED CREDENTIALS:")
        print("Email: uwimana@gmail.com")
        print("Password: Uwimana 123")
        print("=" * 50)
    else:
        print("Failed to update password")