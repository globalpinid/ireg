import numpy as np
import cv2
from insightface.app import FaceAnalysis
from app.config import settings

# Global model instance (loaded once)
_face_app = None


def get_face_app() -> FaceAnalysis:
    global _face_app
    if _face_app is None:
        _face_app = FaceAnalysis(name=settings.model_name, providers=["CPUExecutionProvider"])
        _face_app.prepare(ctx_id=0, det_size=(640, 640))
    return _face_app


def get_embedding_from_image(image_bytes: bytes) -> np.ndarray | None:
    """Extract single face embedding from an individual photo (enrollment)."""
    img = _bytes_to_cv2(image_bytes)
    app = get_face_app()
    faces = app.get(img)
    if not faces:
        return None
    # Return the largest face (most prominent)
    largest = max(faces, key=lambda f: (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1]))
    return largest.embedding


def get_all_embeddings_from_image(image_bytes: bytes) -> list[np.ndarray]:
    """Extract all face embeddings from a group photo (attendance)."""
    img = _bytes_to_cv2(image_bytes)
    app = get_face_app()
    faces = app.get(img)
    return [f.embedding for f in faces]


def get_faces_from_image(image_bytes: bytes) -> tuple[np.ndarray, list[dict]]:
    """Extract face embeddings and bounding boxes from a group photo."""
    img = _bytes_to_cv2(image_bytes)
    app = get_face_app()
    faces = app.get(img)
    return img, [{"embedding": f.embedding, "bbox": f.bbox.astype(int).tolist()} for f in faces]


def compute_similarity(embedding1: np.ndarray, embedding2: np.ndarray) -> float:
    """Cosine similarity between two embeddings."""
    return float(np.dot(embedding1, embedding2) / (np.linalg.norm(embedding1) * np.linalg.norm(embedding2)))


def _bytes_to_cv2(image_bytes: bytes) -> np.ndarray:
    nparr = np.frombuffer(image_bytes, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    return img
