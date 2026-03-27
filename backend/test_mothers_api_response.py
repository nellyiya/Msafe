import requests
import json

def test_mothers_api_response():
    """Test the mothers API response to check appointment data"""
    
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
            
            # Get mothers
            mothers_response = requests.get(
                "http://localhost:8000/mothers",
                headers={
                    "Authorization": f"Bearer {token}",
                    "Content-Type": "application/json"
                },
                timeout=10
            )
            
            if mothers_response.status_code == 200:
                mothers_data = mothers_response.json()
                print(f"MOTHERS: Found {len(mothers_data)} mothers")
                
                # Check appointment data
                with_appointments = 0
                without_appointments = 0
                
                print("\nAPPOINTMENT STATUS:")
                print("-" * 50)
                
                for mother in mothers_data[:10]:  # Check first 10
                    has_appointment = mother.get('hasScheduledAppointment', False)
                    if has_appointment:
                        with_appointments += 1
                    else:
                        without_appointments += 1
                    
                    print(f"{mother['name']}: hasScheduledAppointment = {has_appointment}")
                
                print(f"\nSUMMARY:")
                print(f"With appointments: {with_appointments}")
                print(f"Without appointments: {without_appointments}")
                
                # Show sample mother data structure
                if mothers_data:
                    print(f"\nSAMPLE MOTHER DATA:")
                    print(json.dumps(mothers_data[0], indent=2))
                
                return True
            else:
                print(f"MOTHERS API FAILED: {mothers_response.status_code}")
                return False
        else:
            print("LOGIN FAILED")
            return False
            
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("TESTING MOTHERS API RESPONSE")
    print("=" * 60)
    test_mothers_api_response()