from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:password@localhost:5432/ireg"
    face_similarity_threshold: float = 0.4
    model_name: str = "buffalo_sc"
    gcs_bucket_name: str | None = None
    gcs_folder: str = "student-photos"
    google_cloud_credentials_json: str | None = None

    class Config:
        protected_namespaces = ("settings_",)
        env_file = ".env"
        env_file_encoding = "utf-8"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if self.database_url.startswith("postgres://"):
            self.database_url = self.database_url.replace("postgres://", "postgresql://", 1)


settings = Settings()
