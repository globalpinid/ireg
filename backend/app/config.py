from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Railway injects DATABASE_URL automatically when you add a Postgres plugin
    database_url: str = "postgresql://postgres:password@localhost:5432/ireg"
    face_similarity_threshold: float = 0.4
    model_name: str = "buffalo_sc"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        protected_namespaces = ("settings_",)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        # Railway uses DATABASE_URL with postgres:// scheme, SQLAlchemy needs postgresql://
        if self.database_url.startswith("postgres://"):
            self.database_url = self.database_url.replace("postgres://", "postgresql://", 1)


settings = Settings()
