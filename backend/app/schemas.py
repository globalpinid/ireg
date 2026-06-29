from pydantic import BaseModel
from datetime import date, datetime


class StudentCreate(BaseModel):
    name: str
    belt_color: str = "white"


class StudentResponse(BaseModel):
    id: int
    name: str
    belt_color: str
    photo_url: str | None = None
    enrolled_at: datetime

    class Config:
        from_attributes = True


class AttendanceResult(BaseModel):
    total_detected: int
    total_matched: int
    matched_students: list[dict]
    unmatched_count: int


class SessionResponse(BaseModel):
    id: int
    session_date: date
    session_number: int
    total_detected: int
    total_matched: int
    created_at: datetime

    class Config:
        from_attributes = True


class StudentStats(BaseModel):
    student_name: str
    total_sessions: int
    present: int
    absent: int
    attendance_percentage: float


class DayStats(BaseModel):
    date: date
    sessions: list[SessionResponse]
    unique_students_present: int
