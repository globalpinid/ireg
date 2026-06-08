from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://postgres:password@localhost:5432/ireg"
    face_similarity_threshold: float = 0.4
    model_name: str = "buffalo_sc"

    class Config:
        # Only load .env in development — on Railway, env vars are injected directly
        env_file = ".env"
        env_file_encoding = "utf-8"
        env_file_override = False  # Railway env vars take priority over .env
        protected_namespaces = ("settings_",)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        if self.database_url.startswith("postgres://"):
            self.database_url = self.database_url.replace("postgres://", "postgresql://", 1)


settings = Settings()
