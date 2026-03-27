import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, UserStatus

def fix_user_status_enum():
    db = SessionLocal()
    
    print("FIXING USER STATUS ENUM VALUES")
    print("=" * 50)
    
    users = db.query(User).all()
    
    for user in users:
        print(f"User: {user.name} ({user.email})")
        print(f"  Current status: {user.status}")
        
        # Fix the status enum values
        if hasattr(user.status, 'value'):
            current_status = user.status.value
        else:
            current_status = str(user.status)
        
        print(f"  Status value: {current_status}")
        
        # Map old values to new enum values
        if current_status == 'Active':
            user.status = UserStatus.ACTIVE
            print(f"  Fixed to: ACTIVE")
        elif current_status == 'Pending':
            user.status = UserStatus.PENDING
            print(f"  Fixed to: PENDING")
        elif current_status == 'Suspended':
            user.status = UserStatus.SUSPENDED
            print(f"  Fixed to: SUSPENDED")
        else:
            # Default to ACTIVE if unknown
            user.status = UserStatus.ACTIVE
            print(f"  Set to: ACTIVE (default)")
        
        print("-" * 30)
    
    db.commit()
    db.close()
    
    print("Status enum values fixed!")
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

def test_login_and_me(email, password):
    """Test both login and /auth/me endpoints"""
    import requests
    
    # Test login
    login_data = {
        "email": email,
        "password": password
    }
    
    try:
        # Login
        response = requests.post(
            "http://localhost:8000/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            token_data = response.json()
            token = token_data['access_token']
            print(f"LOGIN: SUCCESS for {email}")
            
            # Test /auth/me
            me_response = requests.get(
                "http://localhost:8000/auth/me",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            
            if me_response.status_code == 200:
                user_data = me_response.json()
                print(f"AUTH/ME: SUCCESS - User: {user_data.get('name', 'Unknown')}")
                return True
            else:
                print(f"AUTH/ME: FAILED - Status: {me_response.status_code}")
                try:
                    error = me_response.json()
                    print(f"AUTH/ME: Error: {error}")
                except:
                    print(f"AUTH/ME: Error text: {me_response.text}")
                return False
        else:
            print(f"LOGIN: FAILED for {email}")
            return False
            
    except Exception as e:
        print(f"TEST ERROR: {e}")
        return False

if __name__ == "__main__":
    print("FIXING DATABASE ENUM ISSUES")
    print("=" * 60)
    
    # Fix the enum values
    fix_user_status_enum()
    
    # Sync databases
    print("\nSyncing databases...")
    sync_databases()
    
    print("\nTesting login and user info retrieval...")
    print("=" * 60)
    
    # Test a few accounts
    test_accounts = [
        ("uwimana@gmail.com", "Uwimana 123"),
        ("berwa@gmail.com", "Berwa 123"),
        ("admin@mamasafe.com", "Admin@2024")
    ]
    
    for email, password in test_accounts:
        print(f"\nTesting: {email}")
        test_login_and_me(email, password)
        print("-" * 40)
    
    print("\nFIX COMPLETE!")
    print("=" * 60)