import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, UserRole, UserStatus
from passlib.context import CryptContext

# Use the same password context as the API
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def fix_all_passwords():
    db = SessionLocal()
    
    # Define passwords for each user type
    passwords = {
        "admin@mamasafe.rw": "admin123",
        "admin@mamasafe.com": "Admin@2024",
        "uwimana@gmail.com": "chw123",
        "berwa@gmail.com": "chw123", 
        "aurore.ismbi@kfh.rw": "doctor123",
        "keza.diana@kibagabagahospital.rw": "doctor123",
        "sonia.uwera@kacyiruhospital.rw": "doctor123"
    }
    
    print("Fixing all user passwords...")
    print("=" * 60)
    
    users = db.query(User).all()
    
    for user in users:
        if user.email in passwords:
            new_password = passwords[user.email]
        else:
            # Default password based on role
            if user.role == UserRole.ADMIN:
                new_password = "admin123"
            elif user.role == UserRole.CHW:
                new_password = "chw123"
            elif user.role == UserRole.HEALTHCARE_PRO:
                new_password = "doctor123"
            else:
                new_password = "default123"
        
        # Hash password using passlib (same as API)
        new_hash = pwd_context.hash(new_password)
        
        print(f"User: {user.name} ({user.email})")
        print(f"   Role: {user.role.value}")
        print(f"   New Password: {new_password}")
        print(f"   Approved: {user.is_approved}")
        print(f"   Status: {user.status.value}")
        
        # Update password
        user.password_hash = new_hash
        
        # Ensure user is approved and active
        user.is_approved = True
        user.status = UserStatus.ACTIVE
        
        print("   Password updated and account activated")
        print("-" * 40)
    
    db.commit()
    db.close()
    
    print("\nALL PASSWORDS FIXED!")
    print("=" * 60)
    print("LOGIN CREDENTIALS:")
    print("=" * 60)
    
    for email, password in passwords.items():
        print(f"Email: {email}")
        print(f"Password: {password}")
        print()
    
    print("DEFAULT PASSWORDS FOR OTHER USERS:")
    print("Admin accounts: admin123")
    print("CHW accounts: chw123") 
    print("Doctor accounts: doctor123")

def test_login(email, password):
    """Test if login works for a user"""
    db = SessionLocal()
    
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print(f"FAIL: User {email} not found")
        return False
    
    # Test password verification
    is_valid = pwd_context.verify(password, user.password_hash)
    
    if is_valid and user.is_approved and user.status == UserStatus.ACTIVE:
        print(f"PASS: {email} - Login will work")
        return True
    else:
        print(f"FAIL: {email} - Login will fail")
        if not is_valid:
            print(f"   - Password incorrect")
        if not user.is_approved:
            print(f"   - Not approved")
        if user.status != UserStatus.ACTIVE:
            print(f"   - Status: {user.status.value}")
        return False

if __name__ == "__main__":
    fix_all_passwords()
    
    print("\nTESTING ALL LOGINS:")
    print("=" * 60)
    
    test_accounts = [
        ("admin@mamasafe.rw", "admin123"),
        ("admin@mamasafe.com", "Admin@2024"),
        ("uwimana@gmail.com", "chw123"),
        ("berwa@gmail.com", "chw123"),
        ("aurore.ismbi@kfh.rw", "doctor123"),
        ("keza.diana@kibagabagahospital.rw", "doctor123"),
        ("sonia.uwera@kacyiruhospital.rw", "doctor123")
    ]
    
    for email, password in test_accounts:
        test_login(email, password)