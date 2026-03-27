import requests
import json

def test_api_endpoint(email, password, base_url="http://localhost:8000"):
    """Test the actual API endpoint"""
    
    print(f"Testing API endpoint: {base_url}/auth/login")
    print(f"Email: {email}")
    print(f"Password: {password}")
    print("-" * 50)
    
    # Prepare login data
    login_data = {
        "email": email,
        "password": password
    }
    
    try:
        # Make the API call
        response = requests.post(
            f"{base_url}/auth/login",
            json=login_data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        try:
            response_json = response.json()
            print(f"Response Body: {json.dumps(response_json, indent=2)}")
        except:
            print(f"Response Text: {response.text}")
        
        if response.status_code == 200:
            print("SUCCESS: Login worked!")
            return True
        else:
            print("FAILED: Login failed")
            return False
            
    except requests.exceptions.ConnectionError:
        print("ERROR: Cannot connect to API server")
        print("Make sure the API server is running on the specified port")
        return False
    except Exception as e:
        print(f"ERROR: {e}")
        return False

def test_api_health(base_url="http://localhost:8000"):
    """Test if API is running"""
    try:
        response = requests.get(f"{base_url}/")
        print(f"API Health Check: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except:
        print("API is not running or not accessible")
        return False

if __name__ == "__main__":
    print("TESTING ACTUAL API ENDPOINT")
    print("=" * 60)
    
    # Test if API is running
    if not test_api_health():
        print("\nAPI server is not running. Please start it first:")
        print("cd backend/api && python -m uvicorn main:app --reload")
        exit(1)
    
    print("\nTesting login endpoints:")
    print("=" * 60)
    
    # Test the problematic account
    test_api_endpoint("uwimana@gmail.com", "chw123")
    
    print("\n" + "-" * 60)
    
    # Test admin account
    test_api_endpoint("admin@mamasafe.com", "Admin@2024")
    
    print("\n" + "-" * 60)
    
    # Test another CHW account
    test_api_endpoint("berwa@gmail.com", "chw123")