from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session as DBSession
from app.database import get_db
from app.models import Student, Session, Attendance
from app.schemas import StudentStats, SessionResponse
from datetime import date, timedelta

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/session/{session_id}", response_model=SessionResponse)
def get_session_stats(session_id: int, db: DBSession = Depends(get_db)):
    """Get stats for a specific session."""
    session = db.query(Session).filter(Session.id == session_id).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    return session


@router.get("/day")
def get_day_stats(target_date: date = Query(default_factory=date.today), db: DBSession = Depends(get_db)):
    """Get attendance stats for a specific day."""
    sessions = (
        db.query(Session)
        .filter(Session.session_date == target_date)
        .order_by(Session.session_number, Session.id)
        .all()
    )
    unique_students = (
        db.query(Attendance.student_id)
        .join(Session)
        .filter(Session.session_date == target_date)
        .distinct()
        .count()
    )
    return {
        "date": target_date,
        "total_sessions": len(sessions),
        "unique_students_present": unique_students,
        "sessions": [_session_summary(db, s) for s in sessions],
    }


def _session_summary(db: DBSession, session: Session) -> dict:
    students = (
        db.query(Student)
        .join(Attendance)
        .filter(Attendance.session_id == session.id)
        .order_by(Student.name)
        .all()
    )
    return {
        "id": session.id,
        "session_number": session.session_number,
        "total_detected": session.total_detected,
        "total_matched": session.total_matched,
        "unique_students_present": len({student.id for student in students}),
        "students": [
            {
                "id": student.id,
                "name": student.name,
                "belt_color": student.belt_color,
                "photo_url": student.photo_url,
            }
            for student in students
        ],
    }


@router.get("/week")
def get_week_stats(week_start: date = Query(default=None), db: DBSession = Depends(get_db)):
    """Get attendance stats for a week."""
    if not week_start:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
    week_end = week_start + timedelta(days=6)

    sessions = db.query(Session).filter(Session.session_date.between(week_start, week_end)).all()
    unique_students = (
        db.query(Attendance.student_id)
        .join(Session)
        .filter(Session.session_date.between(week_start, week_end))
        .distinct()
        .count()
    )
    return {
        "week_start": week_start,
        "week_end": week_end,
        "total_sessions": len(sessions),
        "unique_students_present": unique_students,
    }


@router.get("/month")
def get_month_stats(year: int = Query(default=None), month: int = Query(default=None), db: DBSession = Depends(get_db)):
    """Get attendance stats for a month."""
    today = date.today()
    year = year or today.year
    month = month or today.month
    month_start = date(year, month, 1)
    if month == 12:
        month_end = date(year + 1, 1, 1) - timedelta(days=1)
    else:
        month_end = date(year, month + 1, 1) - timedelta(days=1)

    sessions = db.query(Session).filter(Session.session_date.between(month_start, month_end)).all()
    unique_students = (
        db.query(Attendance.student_id)
        .join(Session)
        .filter(Session.session_date.between(month_start, month_end))
        .distinct()
        .count()
    )
    return {
        "month": f"{year}-{month:02d}",
        "total_sessions": len(sessions),
        "unique_students_present": unique_students,
        "total_days_with_sessions": len(set(s.session_date for s in sessions)),
    }


@router.get("/student/{student_id}", response_model=StudentStats)
def get_student_stats(student_id: int, db: DBSession = Depends(get_db)):
    """Get attendance stats for a specific student."""
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    total_sessions = db.query(Session).count()
    present = db.query(Attendance).filter(Attendance.student_id == student_id).count()
    absent = total_sessions - present
    percentage = (present / total_sessions * 100) if total_sessions > 0 else 0

    return StudentStats(
        student_name=student.name,
        total_sessions=total_sessions,
        present=present,
        absent=absent,
        attendance_percentage=round(percentage, 1),
    )
