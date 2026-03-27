import requests
import json

def test_chat_endpoints():
    """Test the chat API endpoints"""
    
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
            headers = {
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json"
            }
            print("LOGIN: SUCCESS")
            
            # Test chat rooms endpoint
            print("\nTesting chat rooms endpoint...")
            rooms_response = requests.get(
                "http://localhost:8000/chat/rooms",
                headers=headers,
                timeout=10
            )
            
            print(f"Chat rooms status: {rooms_response.status_code}")
            if rooms_response.status_code == 200:
                rooms = rooms_response.json()
                print(f"Found {len(rooms)} chat rooms")
            else:
                print(f"Error: {rooms_response.text}")
            
            # Test create chat room (this will fail without proper referral, but tests the endpoint)
            print("\nTesting create chat room endpoint...")
            create_data = {
                "mother_id": 1,
                "referral_id": 1
            }
            
            create_response = requests.post(
                "http://localhost:8000/chat/rooms",
                json=create_data,
                headers=headers,
                timeout=10
            )
            
            print(f"Create chat room status: {create_response.status_code}")
            if create_response.status_code != 200:
                print(f"Expected error (no referral): {create_response.json()}")
            
            return True
        else:
            print("LOGIN FAILED")
            return False
            
    except Exception as e:
        print(f"ERROR: {e}")
        return False

if __name__ == "__main__":
    print("TESTING CHAT API ENDPOINTS")
    print("=" * 50)
    test_chat_endpoints()
    print("\nTEST COMPLETE")
    print("=" * 50)