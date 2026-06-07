from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException
from sqlalchemy.orm import Session as DBSession
from app.database import get_db
from app.schemas import AttendanceResult
from app.services.attendance_service import process_attendance
from datetime import date

router = APIRouter(prefix="/attendance", tags=["attendance"])


@router.post("/mark", response_model=AttendanceResult)
async def mark_attendance(
    photo: UploadFile = File(...),
    session_date: date = Form(default_factory=date.today),
    session_number: int = Form(default=1),
    db: DBSession = Depends(get_db),
):
    """Upload a group photo to mark attendance for a session."""
    image_bytes = await photo.read()
    result = process_attendance(db, image_bytes, session_date, session_number)
    return result
