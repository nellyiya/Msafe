#!/usr/bin/env python3
"""
Debug script to test admin login and see what's happening
"""
import sys
import os
import requests
import json

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy.orm import Session
from database import engine, get_db, Base
from models import User, UserRole, UserStatus
from auth import get_password_hash, verify_password

def check_admin_in_database():
    """Check if admin user exists in database and verify details"""
    print("Checking admin user in database...")
    
    db = next(get_db())
    
    try:
        # Find admin user
        admin_user = db.query(User).filter(User.email == "admin@mamasafe.com").first()
        
        if not admin_user:
            print("Admin user NOT found in database!")
            return False
        
        print("Admin user found in database:")
        print(f"   ID: {admin_user.id}")
        print(f"   Name: {admin_user.name}")
        print(f"   Email: {admin_user.email}")
        print(f"   Role: {admin_user.role}")
        print(f"   Status: {admin_user.status}")
        print(f"   Is Approved: {admin_user.is_approved}")
        print(f"   Password Hash: {admin_user.password_hash[:50]}...")
        
        # Test password verification
        is_valid = verify_password("Admin@2024", admin_user.password_hash)
        print(f"   Password verification: {'PASS' if is_valid else 'FAIL'}")
        
        return is_valid
        
    except Exception as e:
        print(f"Error checking database: {e}")
        return False
    finally:
        db.close()

def test_api_login():
    """Test login via API with detailed debugging"""
    print("\nTesting API login...")
    
    try:
        url = "http://localhost:8000/auth/login"
        payload = {
            "email": "admin@mamasafe.com",
            "password": "Admin@2024"
        }
        
        print(f"URL: {url}")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(url, json=payload, timeout=10)
        
        print(f"Response Status: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        print(f"Response Body: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            token = data.get("access_token")
            print(f"Login successful! Token: {token[:50]}...")
            return True
        else:
            print(f"Login failed with status {response.status_code}")
            return False
            
    except requests.exceptions.ConnectionError:
        print("Cannot connect to backend server!")
        print("   Make sure the server is running on http://localhost:8000")
        return False
    except Exception as e:
        print(f"Error during API test: {e}")
        return False

def test_server_status():
    """Test if server is running"""
    print("Testing server status...")
    
    try:
        response = requests.get("http://localhost:8000/", timeout=5)
        print(f"Server is running! Status: {response.status_code}")
        print(f"Response: {response.text}")
        return True
    except requests.exceptions.ConnectionError:
        print("Server is NOT running!")
        print("   Start the server with: python -m uvicorn api.main:app --reload --host 0.0.0.0 --port 8000")
        return False
    except Exception as e:
        print(f"Error checking server: {e}")
        return False

def recreate_admin_user():
    """Recreate admin user from scratch"""
    print("\nRecreating admin user from scratch...")
    
    db = next(get_db())
    
    try:
        # Delete existing admin user if exists
        existing_admin = db.query(User).filter(User.email == "admin@mamasafe.com").first()
        if existing_admin:
            db.delete(existing_admin)
            print("Deleted existing admin user")
        
        # Create fresh admin user
        new_password_hash = get_password_hash("Admin@2024")
        print(f"Generated new password hash: {new_password_hash[:50]}...")
        
        admin_user = User(
            name="System Admin",
            email="admin@mamasafe.com",
            phone="+250788000000",
            password_hash=new_password_hash,
            role=UserRole.ADMIN,
            is_approved=True,
            status=UserStatus.ACTIVE
        )
        
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        
        print("New admin user created successfully!")
        
        # Verify the new user
        is_valid = verify_password("Admin@2024", admin_user.password_hash)
        print(f"Password verification: {'PASS' if is_valid else 'FAIL'}")
        
        return True
        
    except Exception as e:
        print(f"Error recreating admin user: {e}")
        db.rollback()
        return False
    finally:
        db.close()

def main():
    print("MamaSafe Admin Login Debug")
    print("=" * 50)
    
    # Step 1: Check server status
    if not test_server_status():
        return 1
    
    # Step 2: Check admin user in database
    if not check_admin_in_database():
        print("\nAdmin user has issues, recreating...")
        if not recreate_admin_user():
            return 1
    
    # Step 3: Test API login
    if not test_api_login():
        print("\nAPI login failed, trying to recreate admin user...")
        if recreate_admin_user():
            print("\nRetrying API login...")
            test_api_login()
    
    print("\nDebug completed!")
    print("Try logging in with:")
    print("   Email: admin@mamasafe.com")
    print("   Password: Admin@2024")
    
    return 0

if __name__ == "__main__":
    exit(main())