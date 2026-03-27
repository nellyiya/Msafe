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
        db.close()
        return False
    
    # Hash password using passlib (same as API)
    new_hash = pwd_context.hash(new_password)
    
    print(f"Updating: {user.name} ({email})")
    print(f"New password: {new_password}")
    
    user.password_hash = new_hash
    db.commit()
    db.close()
    
    print("Password updated successfully!")
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
    print("UPDATING HEALTHCARE PROFESSIONAL PASSWORDS")
    print("=" * 60)
    
    # Healthcare professionals with their new passwords
    healthcare_pros = [
        ("keza.diana@kibagabagahospital.rw", "Keza 123", "Dr. Keza Diana"),
        ("aurore.ismbi@kfh.rw", "Isimbi 123", "Dr. Aurore Isimbi"),
        ("sonia.uwera@kacyiruhospital.rw", "Uwera 123", "Dr. Sonia Uwera")
    ]
    
    successful_updates = 0
    
    for email, password, name in healthcare_pros:
        print(f"\n{name}:")
        print("-" * 40)
        
        if update_user_password(email, password):
            successful_updates += 1
        
        print()
    
    # Sync databases
    print("Syncing databases...")
    sync_databases()
    
    # Test all logins
    print("\nTesting all updated passwords:")
    print("=" * 60)
    
    for email, password, name in healthcare_pros:
        print(f"\nTesting {name}:")
        test_login(email, password)
    
    print(f"\nUPDATE SUMMARY:")
    print("=" * 60)
    print(f"Successfully updated: {successful_updates}/3 accounts")
    
    if successful_updates == 3:
        print("\nALL HEALTHCARE PROFESSIONAL PASSWORDS UPDATED!")
        print("=" * 60)
        print("UPDATED CREDENTIALS:")
        print("=" * 60)
        
        for email, password, name in healthcare_pros:
            print(f"{name}:")
            print(f"  Email: {email}")
            print(f"  Password: {password}")
            print()
    else:
        print("Some updates failed. Please check the errors above.")