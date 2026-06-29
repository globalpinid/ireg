from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
from app.database import init_db
from app.routers import students, attendance, stats

PHOTO_DIR = Path("student_photos")
PHOTO_DIR.mkdir(exist_ok=True)

app = FastAPI(title="iReg - Karate Academy Attendance", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(students.router)
app.include_router(attendance.router)
app.include_router(stats.router)
app.mount("/student-photos", StaticFiles(directory=PHOTO_DIR), name="student_photos")


@app.on_event("startup")
def startup():
    init_db()


@app.get("/")
def root():
    return {"message": "iReg API is running", "docs": "/docs"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
