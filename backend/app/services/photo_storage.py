import json
from pathlib import Path
from uuid import uuid4

from fastapi import Request
from google.cloud import storage
from google.oauth2 import service_account

from app.config import settings

LOCAL_PHOTO_DIR = Path("student_photos")
LOCAL_PHOTO_DIR.mkdir(exist_ok=True)


def save_student_photo(
    image_bytes: bytes,
    original_filename: str | None,
    content_type: str | None,
    request: Request,
) -> str:
    suffix = Path(original_filename or "").suffix.lower()
    if suffix not in {".jpg", ".jpeg", ".png", ".webp"}:
        suffix = ".jpg"

    object_name = f"{uuid4().hex}{suffix}"
    if settings.gcs_bucket_name:
        return _upload_to_gcs(image_bytes, object_name, content_type)

    return _save_locally(image_bytes, object_name, request)


def _upload_to_gcs(image_bytes: bytes, object_name: str, content_type: str | None) -> str:
    client = _gcs_client()
    bucket = client.bucket(settings.gcs_bucket_name)
    blob_name = f"{settings.gcs_folder.strip('/')}/{object_name}" if settings.gcs_folder else object_name
    blob = bucket.blob(blob_name)
    blob.cache_control = "public, max-age=31536000"
    blob.upload_from_string(
        image_bytes,
        content_type=content_type or _content_type_from_name(object_name),
    )
    return f"https://storage.googleapis.com/{settings.gcs_bucket_name}/{blob_name}"


def _gcs_client() -> storage.Client:
    if settings.google_cloud_credentials_json:
        credentials_info = json.loads(settings.google_cloud_credentials_json)
        credentials = service_account.Credentials.from_service_account_info(credentials_info)
        return storage.Client(
            project=credentials_info.get("project_id"),
            credentials=credentials,
        )

    return storage.Client()


def _save_locally(image_bytes: bytes, object_name: str, request: Request) -> str:
    photo_path = LOCAL_PHOTO_DIR / object_name
    photo_path.write_bytes(image_bytes)
    return str(request.url_for("student_photos", path=object_name))


def _content_type_from_name(filename: str) -> str:
    suffix = Path(filename).suffix.lower()
    if suffix == ".png":
        return "image/png"
    if suffix == ".webp":
        return "image/webp"
    return "image/jpeg"
