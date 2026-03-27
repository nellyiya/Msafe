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

def test_login(email, password):
    """Test the login immediately"""
    import requests
    
    login_data = {
        "email": email,
        "password": password
    }
    
    try:
        response = requests.post(
            "http://localhost:8000/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            print("LOGIN TEST: SUCCESS")
            return True
        else:
            print("LOGIN TEST: FAILED")
            return False
            
    except Exception as e:
        print(f"LOGIN TEST: ERROR - {e}")
        return False

if __name__ == "__main__":
    print("UPDATING CHW SANDRA BERWA PASSWORD")
    print("=" * 50)
    
    # Update Sandra Berwa's password
    if update_user_password("berwa@gmail.com", "Berwa 123"):
        # Sync databases
        sync_databases()
        
        # Test the login
        print("\nTesting new password...")
        test_login("berwa@gmail.com", "Berwa 123")
        
        print("\nPassword update completed!")
        print("=" * 50)
        print("UPDATED CREDENTIALS:")
        print("Email: berwa@gmail.com")
        print("Password: Berwa 123")
        print("=" * 50)
    else:
        print("Failed to update password")