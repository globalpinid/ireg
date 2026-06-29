import numpy as np
from sqlalchemy.orm import Session as DBSession
from app.models import Student, Session, Attendance
from app.services.face_service import get_all_embeddings_from_image, compute_similarity
from app.config import settings
from datetime import date


def process_attendance(db: DBSession, image_bytes: bytes, session_date: date, session_number: int) -> dict:
    """Process group photo and mark attendance."""
    # Detect all faces in group photo
    embeddings = get_all_embeddings_from_image(image_bytes)
    total_detected = len(embeddings)

    # Get all enrolled students
    students = db.query(Student).filter(Student.embedding.isnot(None)).all()

    # Create session record
    session = Session(
        session_date=session_date,
        session_number=session_number,
        total_detected=total_detected,
    )
    db.add(session)
    db.flush()

    # Match each detected face against enrolled students
    matched_students = []
    for emb in embeddings:
        best_match = None
        best_score = 0.0

        for student in students:
            stored_emb = np.array(student.embedding)
            score = compute_similarity(emb, stored_emb)
            if score > best_score:
                best_score = score
                best_match = student

        if best_match and best_score >= settings.face_similarity_threshold:
            # Avoid duplicate marking in same session
            if best_match.id not in [s["id"] for s in matched_students]:
                matched_students.append(
                    {
                        "id": best_match.id,
                        "name": best_match.name,
                        "belt_color": best_match.belt_color,
                        "photo_url": best_match.photo_url,
                        "confidence": best_score,
                    }
                )
                attendance = Attendance(
                    student_id=best_match.id,
                    session_id=session.id,
                    confidence=int(best_score * 100),
                )
                db.add(attendance)

    session.total_matched = len(matched_students)
    db.commit()

    return {
        "total_detected": total_detected,
        "total_matched": len(matched_students),
        "matched_students": matched_students,
        "unmatched_count": total_detected - len(matched_students),
    }
