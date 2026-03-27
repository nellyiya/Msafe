import requests
import json

def test_mothers_endpoint():
    """Test the mothers endpoint after schema fix"""
    
    # First login to get token
    login_data = {
        "email": "uwimana@gmail.com",
        "password": "Uwimana 123"
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
            print("LOGIN: SUCCESS")
            
            # Test mothers endpoint
            mothers_response = requests.get(
                "http://localhost:8000/mothers",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            
            print(f"MOTHERS ENDPOINT: Status {mothers_response.status_code}")
            
            if mothers_response.status_code == 200:
                mothers_data = mothers_response.json()
                print(f"SUCCESS: Found {len(mothers_data)} mothers")
                
                # Show first few mothers
                for i, mother in enumerate(mothers_data[:3]):
                    print(f"  {i+1}. {mother['name']} (Age: {mother['age']}) - Risk: {mother['current_risk_level']}")
                
                if len(mothers_data) > 3:
                    print(f"  ... and {len(mothers_data) - 3} more mothers")
                
                return True
            else:
                print(f"FAILED: Status {mothers_response.status_code}")
                try:
                    error = mothers_response.json()
                    print(f"Error: {error}")
                except:
                    print(f"Error text: {mothers_response.text}")
                return False
        else:
            print("LOGIN FAILED")
            return False
            
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("TESTING MOTHERS ENDPOINT AFTER SCHEMA FIX")
    print("=" * 50)
    
    success = test_mothers_endpoint()
    
    print("\n" + "=" * 50)
    if success:
        print("SUCCESS: Mothers endpoint is working!")
        print("CHWs should now see their mothers in the dashboard.")
    else:
        print("FAILED: Mothers endpoint still has issues.")
    print("=" * 50)