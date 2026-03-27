import requests
import json

def test_login_simple(email, password):
    """Simple login test"""
    
    login_data = {"email": email, "password": password}
    
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
            print(f"LOGIN SUCCESS: {email}")
            
            # Test /auth/me
            me_response = requests.get(
                "http://localhost:8000/auth/me",
                headers={"Authorization": f"Bearer {token}"},
                timeout=10
            )
            
            if me_response.status_code == 200:
                user_data = me_response.json()
                print(f"USER INFO SUCCESS: {user_data.get('name')} - {user_data.get('role')}")
                return True
            else:
                print(f"USER INFO FAILED: Status {me_response.status_code}")
                return False
        else:
            print(f"LOGIN FAILED: {email} - Status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"ERROR: {email} - {e}")
        return False

if __name__ == "__main__":
    print("TESTING LOGIN AFTER ENUM FIX")
    print("=" * 50)
    
    # Test key accounts
    accounts = [
        ("uwimana@gmail.com", "Uwimana 123"),
        ("berwa@gmail.com", "Berwa 123"),
        ("admin@mamasafe.com", "Admin@2024")
    ]
    
    for email, password in accounts:
        test_login_simple(email, password)
        print("-" * 30)
    
    print("TEST COMPLETE")