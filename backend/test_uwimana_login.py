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
            print(f"SUCCESS: Login worked!")
            print(f"Token: {token_data['access_token'][:50]}...")
            return True
        else:
            error_data = response.json()
            print(f"FAILED: Login failed")
            print(f"Status: {response.status_code}")
            print(f"Error: {error_data.get('detail', 'Unknown error')}")
            return False
            
    except requests.exceptions.ConnectionError:
        print(f"ERROR: Cannot connect to API server")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("TESTING UPDATED PASSWORD FOR SANDRINE UWIMANA")
    print("=" * 60)
    print("Email: uwimana@gmail.com")
    print("Password: Uwimana 123")
    print("-" * 60)
    
    success = test_login("uwimana@gmail.com", "Uwimana 123")
    
    print("\n" + "=" * 60)
    if success:
        print("CONFIRMED: Sandrine Uwimana can now login with 'Uwimana 123'")
    else:
        print("ISSUE: Password update may not have worked properly")
    print("=" * 60)