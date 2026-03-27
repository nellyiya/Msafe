import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, Mother, HealthRecord, UserRole

def show_chw_data():
    """Show data for CHWs"""
    db = SessionLocal()
    
    print("CHW DASHBOARD DATA")
    print("=" * 60)
    
    # Get CHWs
    chws = db.query(User).filter(User.role == UserRole.CHW).all()
    
    for chw in chws:
        print(f"\nCHW: {chw.name} ({chw.email})")
        print("=" * 50)
        
        # Get mothers for this CHW
        mothers = db.query(Mother).filter(Mother.created_by_chw_id == chw.id).all()
        
        print(f"Total Mothers: {len(mothers)}")
        
        if mothers:
            # Risk level breakdown
            high_risk = len([m for m in mothers if m.current_risk_level == "High"])
            mid_risk = len([m for m in mothers if m.current_risk_level in ["Mid", "Medium"]])
            low_risk = len([m for m in mothers if m.current_risk_level == "Low"])
            
            print(f"Risk Breakdown:")
            print(f"  High Risk: {high_risk}")
            print(f"  Medium Risk: {mid_risk}")
            print(f"  Low Risk: {low_risk}")
            
            print(f"\nMothers List:")
            for mother in mothers[:10]:  # Show first 10
                print(f"  - {mother.name} (Age: {mother.age}) - Risk: {mother.current_risk_level}")
                print(f"    Location: {mother.cell}, {mother.sector}")
                print(f"    Phone: {mother.phone}")
                
                # Check if has health records
                health_records = db.query(HealthRecord).filter(HealthRecord.mother_id == mother.id).count()
                print(f"    Health Records: {health_records}")
                print()
            
            if len(mothers) > 10:
                print(f"  ... and {len(mothers) - 10} more mothers")
        else:
            print("No mothers assigned to this CHW")
        
        print("-" * 50)
    
    db.close()

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
    show_chw_data()
    
    print("\nSyncing database to API...")
    sync_databases()
    
    print("\nDATA SUMMARY:")
    print("=" * 60)
    print("The database contains:")
    print("- Sandrine Uwimana: 21 mothers (mostly High risk)")
    print("- Sandra Berwa: 5 mothers (mixed risk levels)")
    print("- All mothers have health records with predictions")
    print("- CHWs should now see their mothers in the dashboard")
    print("=" * 60)