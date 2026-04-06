# MamaSafe App

## Overview

MamaSafe is a maternal health monitoring system designed to support Community Health Workers (CHWs) in the early detection of pregnancy risks.

The system collects maternal health data, applies a machine learning model to predict pregnancy risk levels (Low, Medium, High), and enables referrals and appointment scheduling between CHWs and healthcare professionals.

The objective of the system is to improve early diagnosis of pregnancy complications and strengthen coordination in maternal healthcare services.

---

## Live Demo

https://resplendent-profiterole-d5bc5d.netlify.app/

---

## System Architecture

MamaSafe follows a client–server architecture:

- Flutter Mobile Application (Frontend)  
- REST API (Backend – Python)  
- Machine Learning Model  
- Database Layer  

### Database Layer

- PostgreSQL (primary database for persistent storage)  
- SQLite (local database for offline functionality in the mobile application)  

---

## Project Structure

MamaSafe-App/
├── backend/
│   ├── app.py
│   ├── model/
│   ├── database/
│   └── requirements.txt
├── mama_safe/
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
└── README.md

## System Requirements

- Flutter SDK  
- Python 3.x  
- PostgreSQL  
- Android Studio or Android Emulator  
- Git  

---

## Installation and Setup

### 1. Clone the Repository

```bash
git clone https://github.com/nellyiya/Msafe.git
cd MamaSafe-App
````

---

## Backend Setup

### 1. Navigate to backend

```bash
cd backend
```

### 2. Create virtual environment

```bash
python -m venv venv
source venv/bin/activate      # Linux/Mac
venv\Scripts\activate         # Windows
```

### 3. Install dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure PostgreSQL

Create a PostgreSQL database and configure your connection:

Example `.env`:

```env
DB_HOST=localhost
DB_NAME=mamasafe
DB_USER=postgres
DB_PASSWORD=your_password
DB_PORT=5432
```

### 5. Run the backend server

```bash
python app.py
```

Backend runs on:

```
http://127.0.0.1:5000/
```

---

## Flutter Application Setup

### 1. Navigate to Flutter project

```bash
cd mama_safe
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

```bash
flutter run
```

Ensure an emulator is running or a physical device is connected.

---

## Machine Learning Model

### Purpose

The model predicts pregnancy risk levels using maternal health indicators.

### Input Features

* Blood Pressure
* Blood Sugar
* Body Temperature
* Heart Rate
* Age

  ## Model Performance Comparison

| Model               | Accuracy |
|--------------------|----------|
| XGBoost            | 87.00%   |
| Random Forest      | 85.22%   |
| LightGBM           | 85.22%   |
| Logistic Regression| 62.07%   |

## System Performance

| Operation              | Response Time |
|------------------------|---------------|
| User Login             | 1.2 seconds   |
| Risk Prediction        | 2.5 seconds   |
| Referral Submission    | 1.8 seconds   |

## System Evaluation

| Metric                         | Value   |
|--------------------------------|--------|
| User Satisfaction Score        | 4.6 / 5 |
| Functional Requirements Met    | 90%     |
| Overall System Readiness       | 95%     |

XGBoost was selected as the final model due to its superior performance and ability to provide reliable pregnancy risk classification within the MamaSafe system.

### Output

* Low Risk
* Medium Risk
* High Risk

### Model Description

The system uses a supervised machine learning model to classify pregnancy risk levels based on input health data.

### Example Predictions

* Normal values result in Low Risk
* Moderate abnormalities result in Medium Risk
* Critical indicators result in High Risk

---

## Core Features

* Maternal health data collection
* Pregnancy risk prediction
* Referral system for high-risk cases
* Appointment scheduling
* Role-based dashboards

### User Roles

* Community Health Worker (CHW)
* Healthcare Professional
* Administrator

---

## API Endpoints (Example)

| Method | Endpoint  | Description            |
| ------ | --------- | ---------------------- |
| POST   | /predict  | Predict pregnancy risk |
| POST   | /login    | User authentication    |
| POST   | /register | User registration      |
| GET    | /patients | Retrieve patient data  |

---

## Testing Strategy

### Functional Testing

Each feature was tested to ensure correct functionality.

### Integration Testing

Verified communication between frontend and backend.

### Validation Testing

Ensured invalid or incomplete inputs are rejected.

---

## Performance

Tested on:

* Android Emulator
* Physical Android devices

The system maintained stable performance across environments.

---

## Analysis

The system successfully meets its objectives by enabling:

* Accurate maternal data collection
* Reliable risk prediction
* Efficient referral processes

A limitation is the dataset size used for training the model.

---

## Future Work

* Improve model accuracy with larger datasets
* Integrate with hospital systems
* Enhance offline synchronization
* Add advanced analytics

---

## Build APK

```bash
flutter build apk --release
```

Output:

```
build/app/outputs/flutter-apk/app-release.apk
```

---



