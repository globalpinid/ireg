from fastapi import FastAPI
from app.database import init_db
from app.routers import students, attendance, stats

app = FastAPI(title="iReg - Karate Academy Attendance", version="1.0.0")

app.include_router(students.router)
app.include_router(attendance.router)
app.include_router(stats.router)


@app.on_event("startup")
def startup():
    init_db()


@app.get("/")
def root():
    return {"message": "iReg API is running", "docs": "/docs"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
