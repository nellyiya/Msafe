import requests
import json

def test_login(email, password, base_url="http://localhost:8000"):
    """Test login for a specific account"""
    
    login_data = {
        "email": email,
        "password": password
    }
    
    try:
        response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            token_data = response.json()
            print(f"✅ {email} - LOGIN SUCCESS")
            print(f"   Token: {token_data['access_token'][:50]}...")
            return True
        else:
            error_data = response.json()
            print(f"❌ {email} - LOGIN FAILED")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {error_data.get('detail', 'Unknown error')}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"❌ {email} - CONNECTION ERROR (API server not running)")
        return False
    except Exception as e:
        print(f"❌ {email} - ERROR: {e}")
        return False

def test_api_health(base_url="http://localhost:8000"):
    """Check if API server is running"""
    try:
        response = requests.get(f"{base_url}/", timeout=5)
        if response.status_code == 200:
            print("✅ API Server is running")
            return True
        else:
            print(f"❌ API Server responded with status {response.status_code}")
            return False
    except:
        print("❌ API Server is not accessible")
        return False

if __name__ == "__main__":
    print("🧪 COMPREHENSIVE LOGIN TEST")
    print("=" * 70)
    
    # Check if API is running
    if not test_api_health():
        print("\n⚠️  API server is not running!")
        print("Please start it with: cd backend/api && python -m uvicorn main:app --reload")
        exit(1)
    
    print("\n📋 TESTING ALL ACCOUNTS:")
    print("=" * 70)
    
    # All test accounts
    test_accounts = [
        # Admin accounts
        ("admin@mamasafe.rw", "admin123", "Admin"),
        ("admin@mamasafe.com", "Admin@2024", "System Admin"),
        
        # CHW accounts  
        ("uwimana@gmail.com", "chw123", "CHW - Sandrine"),
        ("berwa@gmail.com", "chw123", "CHW - Sandra"),
        
        # Healthcare Professional accounts
        ("aurore.ismbi@kfh.rw", "doctor123", "Doctor - King Faisal"),
        ("keza.diana@kibagabagahospital.rw", "doctor123", "Doctor - Kibagabaga"),
        ("sonia.uwera@kacyiruhospital.rw", "doctor123", "Doctor - Kacyiru")
    ]
    
    successful_logins = 0
    total_accounts = len(test_accounts)
    
    for email, password, description in test_accounts:
        print(f"\n🔐 Testing: {description}")
        if test_login(email, password):
            successful_logins += 1
        print("-" * 50)
    
    print(f"\n📊 RESULTS SUMMARY:")
    print("=" * 70)
    print(f"✅ Successful logins: {successful_logins}/{total_accounts}")
    print(f"❌ Failed logins: {total_accounts - successful_logins}/{total_accounts}")
    
    if successful_logins == total_accounts:
        print("\n🎉 ALL ACCOUNTS WORKING PERFECTLY!")
        print("You can now login with any of the tested credentials.")
    else:
        print(f"\n⚠️  {total_accounts - successful_logins} accounts need attention.")
        
    print("\n📝 QUICK REFERENCE - WORKING CREDENTIALS:")
    print("=" * 70)
    for email, password, description in test_accounts:
        print(f"{description}:")
        print(f"  📧 {email}")
        print(f"  🔐 {password}")
        print()