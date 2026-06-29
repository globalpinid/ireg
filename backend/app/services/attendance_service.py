import numpy as np
import cv2
import base64
from sqlalchemy.orm import Session as DBSession
from app.models import Student, Session, Attendance
from app.services.face_service import get_faces_from_image, compute_similarity
from app.config import settings
from datetime import date


def process_attendance(db: DBSession, image_bytes: bytes, session_date: date, session_number: int) -> dict:
    """Process group photo and mark attendance."""
    # Detect all faces in group photo
    img, detected_faces = get_faces_from_image(image_bytes)
    total_detected = len(detected_faces)

    # Get all enrolled students
    students = db.query(Student).filter(Student.embedding.isnot(None)).all()

    session = (
        db.query(Session)
        .filter(
            Session.session_date == session_date,
            Session.session_number == session_number,
        )
        .order_by(Session.id)
        .first()
    )
    if session:
        session.total_detected = (session.total_detected or 0) + total_detected
    else:
        session = Session(
            session_date=session_date,
            session_number=session_number,
            total_detected=total_detected,
        )
        db.add(session)
        db.flush()

    # Match each detected face against enrolled students
    matched_students = []
    detections = []
    for face in detected_faces:
        emb = face["embedding"]
        best_match = None
        best_score = 0.0

        for student in students:
            stored_emb = np.array(student.embedding)
            score = compute_similarity(emb, stored_emb)
            if score > best_score:
                best_score = score
                best_match = student

        is_matched = best_match and best_score >= settings.face_similarity_threshold
        detections.append(
            {
                "bbox": face["bbox"],
                "matched": bool(is_matched),
                "student_name": best_match.name if is_matched else None,
            }
        )

        if is_matched:
            already_marked = (
                db.query(Attendance)
                .join(Session, Session.id == Attendance.session_id)
                .filter(
                    Attendance.student_id == best_match.id,
                    Session.session_date == session_date,
                    Session.session_number == session_number,
                )
                .first()
            )

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

            if not already_marked:
                attendance = Attendance(
                    student_id=best_match.id,
                    session_id=session.id,
                    confidence=int(best_score * 100),
                )
                db.add(attendance)

    session.total_matched = (
        db.query(Attendance.student_id)
        .join(Session, Session.id == Attendance.session_id)
        .filter(
            Session.session_date == session_date,
            Session.session_number == session_number,
        )
        .distinct()
        .count()
    )
    db.commit()

    return {
        "total_detected": total_detected,
        "total_matched": len(matched_students),
        "matched_students": matched_students,
        "unmatched_count": total_detected - len(matched_students),
        "annotated_image": _annotate_image(img, detections),
    }


def _annotate_image(img: np.ndarray, detections: list[dict]) -> str | None:
    if img is None:
        return None

    annotated = img.copy()
    for detection in detections:
        x1, y1, x2, y2 = detection["bbox"]
        color = (0, 180, 0) if detection["matched"] else (0, 0, 255)
        cv2.rectangle(annotated, (x1, y1), (x2, y2), color, 4)

    annotated = _resize_for_preview(annotated)
    ok, encoded = cv2.imencode(".jpg", annotated, [int(cv2.IMWRITE_JPEG_QUALITY), 90])
    if not ok:
        return None
    return base64.b64encode(encoded.tobytes()).decode("utf-8")


def _resize_for_preview(img: np.ndarray, max_size: int = 1600) -> np.ndarray:
    height, width = img.shape[:2]
    longest_side = max(width, height)
    if longest_side <= max_size:
        return img

    scale = max_size / longest_side
    return cv2.resize(img, (int(width * scale), int(height * scale)), interpolation=cv2.INTER_AREA)
