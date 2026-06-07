FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libgomp1 \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .

# Install onnxruntime first (pre-built wheel) then the rest
RUN pip install --no-cache-dir onnxruntime==1.16.0
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app/ ./app/

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
