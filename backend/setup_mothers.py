import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, Mother, UserRole
from datetime import datetime, timedelta

def check_existing_mothers():
    """Check what mothers exist in the database"""
    db = SessionLocal()
    
    print("CHECKING EXISTING MOTHERS")
    print("=" * 50)
    
    mothers = db.query(Mother).all()
    
    if not mothers:
        print("No mothers found in database")
        return []
    
    for mother in mothers:
        chw = db.query(User).filter(User.id == mother.created_by_chw_id).first()
        chw_name = chw.name if chw else "Unknown CHW"
        
        print(f"Mother: {mother.name} (Age: {mother.age})")
        print(f"  Location: {mother.cell}, {mother.sector}, {mother.district}")
        print(f"  Created by CHW: {chw_name} (ID: {mother.created_by_chw_id})")
        print(f"  Risk Level: {mother.current_risk_level}")
        print("-" * 30)
    
    db.close()
    return mothers

def get_chws():
    """Get all CHW users"""
    db = SessionLocal()
    
    chws = db.query(User).filter(User.role == UserRole.CHW).all()
    
    print("AVAILABLE CHWs:")
    print("=" * 30)
    for chw in chws:
        print(f"ID: {chw.id} - {chw.name} ({chw.email})")
    
    db.close()
    return chws

def create_test_mothers():
    """Create test mothers for CHWs"""
    db = SessionLocal()
    
    # Get CHWs
    chws = db.query(User).filter(User.role == UserRole.CHW).all()
    
    if not chws:
        print("No CHWs found!")
        return
    
    print("CREATING TEST MOTHERS")
    print("=" * 50)
    
    # Test mothers data
    test_mothers = [
        {
            "name": "Marie Uwimana",
            "age": 25,
            "phone": "+250788123456",
            "province": "Kigali City",
            "district": "Gasabo",
            "sector": "Kimironko",
            "cell": "Kimisagara",
            "village": "Ubumwe",
            "current_risk_level": "Low"
        },
        {
            "name": "Grace Mukamana",
            "age": 28,
            "phone": "+250788234567",
            "province": "Kigali City",
            "district": "Gasabo",
            "sector": "Kimironko",
            "cell": "Kibagabaga",
            "village": "Amahoro",
            "current_risk_level": "Medium"
        },
        {
            "name": "Jeanne Uwizeye",
            "age": 32,
            "phone": "+250788345678",
            "province": "Kigali City",
            "district": "Gasabo",
            "sector": "Kimironko",
            "cell": "Nyarutarama",
            "village": "Ubwiyunge",
            "current_risk_level": "High"
        },
        {
            "name": "Alice Mukamazimpaka",
            "age": 22,
            "phone": "+250788456789",
            "province": "Kigali City",
            "district": "Gasabo",
            "sector": "Kimironko",
            "cell": "Kimisagara",
            "village": "Ubumwe",
            "current_risk_level": "Low"
        },
        {
            "name": "Esperance Nyirahabimana",
            "age": 35,
            "phone": "+250788567890",
            "province": "Kigali City",
            "district": "Gasabo",
            "sector": "Kimironko",
            "cell": "Kibagabaga",
            "village": "Amahoro",
            "current_risk_level": "High"
        }
    ]
    
    # Create mothers for each CHW
    for i, chw in enumerate(chws):
        print(f"Creating mothers for CHW: {chw.name}")
        
        # Give each CHW 2-3 mothers
        start_idx = i * 2
        end_idx = min(start_idx + 3, len(test_mothers))
        
        for j in range(start_idx, end_idx):
            if j < len(test_mothers):
                mother_data = test_mothers[j].copy()
                
                # Calculate pregnancy dates
                pregnancy_start = datetime.now() - timedelta(days=120)  # 4 months pregnant
                due_date = pregnancy_start + timedelta(days=280)  # 9 months total
                
                mother = Mother(
                    name=mother_data["name"],
                    age=mother_data["age"],
                    phone=mother_data["phone"],
                    province=mother_data["province"],
                    district=mother_data["district"],
                    sector=mother_data["sector"],
                    cell=mother_data["cell"],
                    village=mother_data["village"],
                    pregnancy_start_date=pregnancy_start,
                    due_date=due_date,
                    created_by_chw_id=chw.id,
                    current_risk_level=mother_data["current_risk_level"],
                    has_allergies=False,
                    has_chronic_condition=False,
                    on_medication=False
                )
                
                db.add(mother)
                print(f"  Added: {mother.name} (Risk: {mother.current_risk_level})")
    
    db.commit()
    db.close()
    
    print("Test mothers created successfully!")

def sync_databases():
    """Copy the main database to the API directory"""
    import shutil
    try:
        shutil.copy("mamasafe.db", "api/mamasafe.db")
        print("Database synced to API directory")
        return True
    except Exception as e:
        print(f"Error syncing database: {e}")
        return False

if __name__ == "__main__":
    print("MOTHERS DATABASE SETUP")
    print("=" * 60)
    
    # Check existing mothers
    existing_mothers = check_existing_mothers()
    
    print()
    
    # Get CHWs
    chws = get_chws()
    
    print()
    
    if not existing_mothers:
        print("No mothers found. Creating test mothers...")
        create_test_mothers()
        
        # Sync databases
        print("\nSyncing databases...")
        sync_databases()
        
        print("\nChecking created mothers...")
        check_existing_mothers()
    else:
        print(f"Found {len(existing_mothers)} existing mothers")
        
        # Check if CHWs have mothers assigned
        db = SessionLocal()
        for chw in chws:
            mother_count = db.query(Mother).filter(Mother.created_by_chw_id == chw.id).count()
            print(f"{chw.name}: {mother_count} mothers")
        db.close()
        
        if input("\nCreate additional test mothers? (y/n): ").lower() == 'y':
            create_test_mothers()
            sync_databases()
    
    print("\nSETUP COMPLETE!")
    print("=" * 60)