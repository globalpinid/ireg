from fastapi import APIRouter, Depends, UploadFile, File, Form, HTTPException, Request
from sqlalchemy.orm import Session as DBSession
from app.database import get_db
from app.models import Student
from app.schemas import StudentResponse
from app.services.face_service import get_embedding_from_image
from app.services.photo_storage import save_student_photo

router = APIRouter(prefix="/students", tags=["students"])


@router.post("/enroll", response_model=StudentResponse)
async def enroll_student(
    request: Request,
    name: str = Form(...),
    belt_color: str = Form("white"),
    photo: UploadFile = File(...),
    db: DBSession = Depends(get_db),
):
    image_bytes = await photo.read()
    embedding = get_embedding_from_image(image_bytes)

    if embedding is None:
        raise HTTPException(status_code=400, detail="No face detected in the photo")

    photo_url = save_student_photo(
        image_bytes=image_bytes,
        original_filename=photo.filename,
        content_type=photo.content_type,
        request=request,
    )

    student = Student(
        name=name,
        belt_color=belt_color,
        embedding=embedding.tolist(),
        photo_url=photo_url,
    )
    db.add(student)
    db.commit()
    db.refresh(student)
    return student


@router.get("/", response_model=list[StudentResponse])
def list_students(db: DBSession = Depends(get_db)):
    """List all enrolled students."""
    return db.query(Student).all()


@router.get("/{student_id}", response_model=StudentResponse)
def get_student(student_id: int, db: DBSession = Depends(get_db)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


@router.delete("/{student_id}")
def delete_student(student_id: int, db: DBSession = Depends(get_db)):
    student = db.query(Student).filter(Student.id == student_id).first()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    db.delete(student)
    db.commit()
    return {"message": f"Student '{student.name}' deleted"}
