import requests
import json

def test_mothers_detailed():
    """Test mothers API with detailed response inspection"""
    
    # Login first
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
            
            # Get mothers with detailed inspection
            mothers_response = requests.get(
                "http://localhost:8000/mothers",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            
            print(f"RESPONSE STATUS: {mothers_response.status_code}")
            print(f"RESPONSE HEADERS: {dict(mothers_response.headers)}")
            
            if mothers_response.status_code == 200:
                mothers_data = mothers_response.json()
                print(f"MOTHERS COUNT: {len(mothers_data)}")
                
                if mothers_data:
                    first_mother = mothers_data[0]
                    print(f"\nFIRST MOTHER KEYS: {list(first_mother.keys())}")
                    print(f"HAS 'hasScheduledAppointment' KEY: {'hasScheduledAppointment' in first_mother}")
                    
                    if 'hasScheduledAppointment' in first_mother:
                        print(f"hasScheduledAppointment VALUE: {first_mother['hasScheduledAppointment']}")
                    
                    print(f"\nFULL FIRST MOTHER DATA:")
                    print(json.dumps(first_mother, indent=2, default=str))
                
                return True
            else:
                print(f"MOTHERS API FAILED: {mothers_response.status_code}")
                print(f"ERROR: {mothers_response.text}")
                return False
        else:
            print("LOGIN FAILED")
            return False
            
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("DETAILED MOTHERS API TEST")
    print("=" * 60)
    test_mothers_detailed()