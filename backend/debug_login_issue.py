import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User
from passlib.context import CryptContext
import requests

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def check_database_user(email):
    """Check user in the main database"""
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    
    if user:
        print(f"MAIN DB - User found: {user.name}")
        print(f"MAIN DB - Email: {user.email}")
        print(f"MAIN DB - Password hash: {user.password_hash[:50]}...")
        print(f"MAIN DB - Approved: {user.is_approved}")
        print(f"MAIN DB - Status: {user.status}")
    else:
        print("MAIN DB - User not found")
    
    db.close()
    return user

def check_api_database_user(email):
    """Check user in the API database"""
    import sqlite3
    
    try:
        conn = sqlite3.connect('api/mamasafe.db')
        cursor = conn.cursor()
        
        cursor.execute("SELECT name, email, password_hash, is_approved, status FROM users WHERE email = ?", (email,))
        result = cursor.fetchone()
        
        if result:
            print(f"API DB - User found: {result[0]}")
            print(f"API DB - Email: {result[1]}")
            print(f"API DB - Password hash: {result[2][:50]}...")
            print(f"API DB - Approved: {result[3]}")
            print(f"API DB - Status: {result[4]}")
        else:
            print("API DB - User not found")
        
        conn.close()
        return result
    except Exception as e:
        print(f"API DB - Error: {e}")
        return None

def test_password_verification(email, password):
    """Test password verification directly"""
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    
    if user:
        is_valid = pwd_context.verify(password, user.password_hash)
        print(f"PASSWORD TEST - Verification result: {is_valid}")
        
        # Try creating a new hash to compare
        new_hash = pwd_context.hash(password)
        print(f"PASSWORD TEST - New hash would be: {new_hash[:50]}...")
        
        return is_valid
    else:
        print("PASSWORD TEST - User not found")
        return False
    
    db.close()

def test_api_login(email, password):
    """Test actual API login"""
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
        
        print(f"API LOGIN - Status: {response.status_code}")
        
        if response.status_code == 200:
            token_data = response.json()
            print(f"API LOGIN - SUCCESS")
            print(f"API LOGIN - Token: {token_data['access_token'][:50]}...")
            return True
        else:
            error_data = response.json()
            print(f"API LOGIN - FAILED")
            print(f"API LOGIN - Error: {error_data.get('detail', 'Unknown error')}")
            return False
            
    except Exception as e:
        print(f"API LOGIN - ERROR: {e}")
        return False

def check_database_files():
    """Check if database files exist and their sizes"""
    import os
    
    main_db = "mamasafe.db"
    api_db = "api/mamasafe.db"
    
    if os.path.exists(main_db):
        size = os.path.getsize(main_db)
        print(f"MAIN DB - Exists, size: {size} bytes")
    else:
        print("MAIN DB - Does not exist")
    
    if os.path.exists(api_db):
        size = os.path.getsize(api_db)
        print(f"API DB - Exists, size: {size} bytes")
    else:
        print("API DB - Does not exist")

if __name__ == "__main__":
    print("COMPREHENSIVE LOGIN DEBUG")
    print("=" * 60)
    
    # Test with the user you're trying to login with
    test_email = "uwimana@gmail.com"
    test_password = "Uwimana 123"
    
    print(f"Testing: {test_email}")
    print(f"Password: {test_password}")
    print("=" * 60)
    
    print("\n1. CHECKING DATABASE FILES:")
    print("-" * 40)
    check_database_files()
    
    print("\n2. CHECKING MAIN DATABASE:")
    print("-" * 40)
    check_database_user(test_email)
    
    print("\n3. CHECKING API DATABASE:")
    print("-" * 40)
    check_api_database_user(test_email)
    
    print("\n4. TESTING PASSWORD VERIFICATION:")
    print("-" * 40)
    test_password_verification(test_email, test_password)
    
    print("\n5. TESTING API LOGIN:")
    print("-" * 40)
    test_api_login(test_email, test_password)
    
    print("\n" + "=" * 60)
    print("DEBUG COMPLETE")
    print("=" * 60)