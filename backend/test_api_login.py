import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, UserStatus
from passlib.context import CryptContext

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def test_api_login_logic(email, password):
    """Test the exact same logic as the API login endpoint"""
    db = SessionLocal()
    
    print(f"Testing login for: {email}")
    print(f"Password: {password}")
    print("-" * 50)
    
    # Step 1: Check hardcoded admin (from API logic)
    if email.lower() == "admin@mamasafe.com" and password == "Admin@2024":
        print("HARDCODED ADMIN LOGIN - Should work")
        return True
    
    # Step 2: Find user in database
    db_user = db.query(User).filter(User.email == email).first()
    
    if not db_user:
        print("ERROR: User not found in database")
        return False
    
    print(f"User found: {db_user.name}")
    print(f"Email in DB: {db_user.email}")
    print(f"Role: {db_user.role}")
    print(f"Password hash: {db_user.password_hash[:50]}...")
    
    # Step 3: Verify password
    password_valid = pwd_context.verify(password, db_user.password_hash)
    print(f"Password verification: {password_valid}")
    
    if not password_valid:
        print("ERROR: Password verification failed")
        return False
    
    # Step 4: Check account status
    print(f"Account status: {db_user.status}")
    print(f"Is approved: {db_user.is_approved}")
    
    if db_user.status == UserStatus.PENDING:
        print("ERROR: Account is PENDING approval")
        return False
    
    if db_user.status == UserStatus.SUSPENDED:
        print("ERROR: Account is SUSPENDED")
        return False
    
    if not db_user.is_approved:
        print("ERROR: Account is not approved")
        return False
    
    print("SUCCESS: All checks passed - login should work")
    return True

def check_api_imports():
    """Check if the API can import the auth functions correctly"""
    try:
        sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'api'))
        from auth import verify_password, get_password_hash
        print("API auth imports: SUCCESS")
        
        # Test with a known password
        test_hash = get_password_hash("chw123")
        test_verify = verify_password("chw123", test_hash)
        print(f"API password test: {test_verify}")
        
        return True
    except Exception as e:
        print(f"API auth imports: FAILED - {e}")
        return False

if __name__ == "__main__":
    print("TESTING API LOGIN LOGIC")
    print("=" * 60)
    
    # Test the problematic account
    test_api_login_logic("uwimana@gmail.com", "chw123")
    
    print("\n" + "=" * 60)
    print("CHECKING API IMPORTS")
    print("=" * 60)
    check_api_imports()
    
    print("\n" + "=" * 60)
    print("TESTING OTHER ACCOUNTS")
    print("=" * 60)
    
    test_accounts = [
        ("admin@mamasafe.com", "Admin@2024"),
        ("berwa@gmail.com", "chw123"),
        ("aurore.ismbi@kfh.rw", "doctor123")
    ]
    
    for email, password in test_accounts:
        print()
        test_api_login_logic(email, password)