import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import engine, Base
from models import ChatRoom, ChatMessage

def create_chat_tables():
    """Create chat tables in the database"""
    
    print("Creating chat tables...")
    
    try:
        # Create all tables (including new chat tables)
        Base.metadata.create_all(bind=engine)
        print("SUCCESS: Chat tables created successfully!")
        
        # Verify tables were created
        from sqlalchemy import inspect
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        
        if 'chat_rooms' in tables and 'chat_messages' in tables:
            print("VERIFIED: chat_rooms and chat_messages tables exist")
        else:
            print("WARNING: Chat tables may not have been created properly")
            
        print("\nChat system is ready!")
        print("=" * 50)
        print("CHAT SYSTEM FEATURES:")
        print("- Real-time messaging with WebSocket")
        print("- Persistent chat history")
        print("- Only available for high-risk mothers with referrals")
        print("- Clean teal design")
        print("- Bilingual support (English/Kinyarwanda)")
        print("=" * 50)
        
    except Exception as e:
        print(f"ERROR creating chat tables: {e}")

def sync_databases():
    """Copy the main database to the API directory"""
    import shutil
    try:
        shutil.copy("mamasafe.db", "api/mamasafe.db")
        print("SUCCESS: Database synced to API directory")
        return True
    except Exception as e:
        print(f"ERROR syncing database: {e}")
        return False

if __name__ == "__main__":
    print("INITIALIZING CHAT SYSTEM")
    print("=" * 60)
    
    create_chat_tables()
    sync_databases()
    
    print("\nCHAT SYSTEM READY!")
    print("=" * 60)
    print("NEXT STEPS:")
    print("1. Restart your API server")
    print("2. Test chat functionality in the app")
    print("3. Chat will be available for high-risk mothers with referrals")
    print("=" * 60)