import requests
import json

def test_complete_login_flow(email, password):
    """Test complete login flow including /auth/me"""
    
    print(f"Testing complete login flow for: {email}")
    print("-" * 50)
    
    # Step 1: Login
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
            token_data = response.json()
            token = token_data['access_token']
            print("✅ LOGIN: SUCCESS")
            print(f"   Token: {token[:50]}...")
            
            # Step 2: Test /auth/me
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
                print("✅ AUTH/ME: SUCCESS")
                print(f"   User: {user_data.get('name', 'Unknown')}")
                print(f"   Role: {user_data.get('role', 'Unknown')}")
                print(f"   Status: {user_data.get('status', 'Unknown')}")
                return True
            else:
                print("❌ AUTH/ME: FAILED")
                print(f"   Status: {me_response.status_code}")
                try:
                    error = me_response.json()
                    print(f"   Error: {error}")
                except:
                    print(f"   Error text: {me_response.text}")
                return False
        else:
            print("❌ LOGIN: FAILED")
            print(f"   Status: {response.status_code}")
            try:
                error = response.json()
                print(f"   Error: {error}")
            except:
                print(f"   Error text: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

if __name__ == "__main__":
    print("TESTING COMPLETE LOGIN FLOW AFTER ENUM FIX")
    print("=" * 60)
    
    # Test accounts with their new passwords
    test_accounts = [
        ("uwimana@gmail.com", "Uwimana 123", "CHW Sandrine"),
        ("berwa@gmail.com", "Berwa 123", "CHW Sandra"),
        ("keza.diana@kibagabagahospital.rw", "Keza 123", "Dr. Keza"),
        ("admin@mamasafe.com", "Admin@2024", "System Admin")
    ]
    
    successful_tests = 0
    
    for email, password, description in test_accounts:
        print(f"\n{description}:")
        if test_complete_login_flow(email, password):
            successful_tests += 1
        print("=" * 60)
    
    print(f"\nRESULTS: {successful_tests}/{len(test_accounts)} accounts working completely")
    
    if successful_tests == len(test_accounts):
        print("🎉 ALL ACCOUNTS WORKING PERFECTLY!")
        print("Login and user info retrieval both work!")
    else:
        print("⚠️  Some accounts still have issues")