import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import User, Mother, HealthRecord, Visit, Referral, UserRole

def get_all_database_data():
    """Get all data from the database"""
    db = SessionLocal()
    
    print("DATABASE CONTENTS")
    print("=" * 60)
    
    # Users
    print("\n1. USERS:")
    print("-" * 30)
    users = db.query(User).all()
    for user in users:
        print(f"ID: {user.id} | {user.name} | {user.email} | Role: {user.role.value}")
    
    print(f"\nTotal Users: {len(users)}")
    
    # Mothers
    print("\n2. MOTHERS:")
    print("-" * 30)
    mothers = db.query(Mother).all()
    
    if mothers:
        for mother in mothers:
            chw = db.query(User).filter(User.id == mother.created_by_chw_id).first()
            chw_name = chw.name if chw else "Unknown"
            
            print(f"ID: {mother.id} | {mother.name} | Age: {mother.age}")
            print(f"   Location: {mother.cell}, {mother.sector}")
            print(f"   CHW: {chw_name} (ID: {mother.created_by_chw_id})")
            print(f"   Risk: {mother.current_risk_level}")
            print(f"   Phone: {mother.phone}")
            print()
    else:
        print("No mothers found")
    
    print(f"Total Mothers: {len(mothers)}")
    
    # Health Records
    print("\n3. HEALTH RECORDS:")
    print("-" * 30)
    health_records = db.query(HealthRecord).all()
    
    if health_records:
        for record in health_records:
            mother = db.query(Mother).filter(Mother.id == record.mother_id).first()
            mother_name = mother.name if mother else "Unknown"
            
            print(f"ID: {record.id} | Mother: {mother_name}")
            print(f"   BP: {record.systolic_bp}/{record.diastolic_bp}")
            print(f"   Blood Sugar: {record.blood_sugar}")
            print(f"   Risk: {record.risk_level}")
            print()
    else:
        print("No health records found")
    
    print(f"Total Health Records: {len(health_records)}")
    
    # Visits
    print("\n4. VISITS:")
    print("-" * 30)
    visits = db.query(Visit).all()
    
    if visits:
        for visit in visits:
            mother = db.query(Mother).filter(Mother.id == visit.mother_id).first()
            chw = db.query(User).filter(User.id == visit.chw_id).first()
            
            mother_name = mother.name if mother else "Unknown"
            chw_name = chw.name if chw else "Unknown"
            
            print(f"ID: {visit.id} | Mother: {mother_name} | CHW: {chw_name}")
            print(f"   Date: {visit.visit_date}")
            print(f"   Completed: {visit.completed}")
            print()
    else:
        print("No visits found")
    
    print(f"Total Visits: {len(visits)}")
    
    # Referrals
    print("\n5. REFERRALS:")
    print("-" * 30)
    referrals = db.query(Referral).all()
    
    if referrals:
        for referral in referrals:
            mother = db.query(Mother).filter(Mother.id == referral.mother_id).first()
            chw = db.query(User).filter(User.id == referral.chw_id).first()
            
            mother_name = mother.name if mother else "Unknown"
            chw_name = chw.name if chw else "Unknown"
            
            print(f"ID: {referral.id} | Mother: {mother_name} | CHW: {chw_name}")
            print(f"   Hospital: {referral.hospital}")
            print(f"   Status: {referral.status}")
            print(f"   Severity: {referral.severity}")
            print()
    else:
        print("No referrals found")
    
    print(f"Total Referrals: {len(referrals)}")
    
    # Summary by CHW
    print("\n6. MOTHERS BY CHW:")
    print("-" * 30)
    chws = db.query(User).filter(User.role == UserRole.CHW).all()
    
    for chw in chws:
        mother_count = db.query(Mother).filter(Mother.created_by_chw_id == chw.id).count()
        print(f"{chw.name} ({chw.email}): {mother_count} mothers")
    
    db.close()
    
    print("\n" + "=" * 60)
    print("DATABASE SCAN COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    get_all_database_data()