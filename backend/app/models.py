from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Date
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from datetime import datetime, timezone
from app.database import Base


class Student(Base):
    __tablename__ = "students"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    belt_color = Column(String, default="white")
    embedding = Column(Vector(512))
    photo_url = Column(String, nullable=True)
    enrolled_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    attendances = relationship("Attendance", back_populates="student")


class Session(Base):
    __tablename__ = "sessions"

    id = Column(Integer, primary_key=True, index=True)
    session_date = Column(Date, nullable=False)
    session_number = Column(Integer, nullable=False)  # 1st, 2nd, 3rd session of the day
    total_detected = Column(Integer, default=0)
    total_matched = Column(Integer, default=0)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    attendances = relationship("Attendance", back_populates="session")


class Attendance(Base):
    __tablename__ = "attendances"

    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)
    session_id = Column(Integer, ForeignKey("sessions.id"), nullable=False)
    confidence = Column(Integer)  # match confidence percentage
    marked_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    student = relationship("Student", back_populates="attendances")
    session = relationship("Session", back_populates="attendances")
