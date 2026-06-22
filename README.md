# iReg - Karate Academy Attendance System

AI-powered visual attendance system using face recognition.

## How It Works

1. Enroll students with individual photos
2. Take group photo during karate session
3. System detects faces, matches against enrolled students, marks attendance
4. View stats per session, day, week, month, or per student

## Tech Stack

- **Backend**: FastAPI (Python)
- **Face Recognition**: InsightFace (ONNX)
- **Database**: PostgreSQL + pgvector
- **Frontend**: Flutter (coming in Phase 2)

## Setup

### Prerequisites

- Python 3.11+
- PostgreSQL with pgvector extension
- Webcam/tablet camera

### Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # Edit with your DB credentials
python -m app.main
```

API docs available at: http://localhost:8000/docs

setup and installations

brew install postgresql@16
brew services stop postgresql@16
brew uninstall postgresql@16
brew install postgresql@17
brew services start postgresql@17
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
createdb ireg
psql ireg -c "CREATE EXTENSION IF NOT EXISTS vector;"

---check vector extention if its working
psql ireg -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"

make sure python version is
brew install python@3.11

cd /Users/kkts/Documents/projects/personal/ireg/backend
rm -rf venv
/opt/homebrew/opt/python@3.11/bin/python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

flutter installation---
brew install --cask flutter

create directory-project--
cd /Users/kkts/Documents/projects/personal/ireg && flutter create --project-name ireg_app frontend

install flutter dependencies --

cd /Users/kkts/Documents/projects/personal/ireg/frontend && flutter pub get 2>&1 | tail -10

--Building the Flutter web app to verify no compilation errors

cd /Users/kkts/Documents/projects/personal/ireg/frontend && flutter build web 2>&1 | tail -5

--build the apk file

cd d:\projects\ireg\frontend
flutter clean
flutter pub get
flutter build apk --dart-define=API_URL=https://ireg-production.up.railway.app

--to deploy in platstore (only first time)

cd d:\projects\ireg\frontend
keytool -genkey -v -keystore ireg-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias ireg

move ireg-keystore.jks android\app\ireg-keystore.jks

(do this always when ever you want to re or deploy)
flutter build appbundle --dart-define=API_URL=https://ireg-production.up.railway.app

cd d:\projects\ireg\frontend

> > flutter build apk --dart-define=API_URL=https://ireg-production.up.railway.app
