# --------- Base build stage for frontend ---------
  FROM node:18-bullseye-slim AS frontend-build

  WORKDIR /app

  # Install build essentials and yarn
  RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    build-essential \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

  RUN npm install -g yarn@1.22.10

  # Copy only frontend files
  COPY client /app

  # Install and build frontend
  RUN yarn install --frozen-lockfile
  RUN yarn build


  # --------- Python backend build stage ---------
  FROM python:3.9-slim AS backend-build

  WORKDIR /app

  # Install build dependencies
  RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

  # Install Python dependencies
  COPY requirements.txt requirements_dev.txt ./
  RUN pip install --no-cache-dir -r requirements.txt -r requirements_dev.txt

  # Copy backend files
  COPY . .

  # --------- Final runtime stage ---------
  FROM python:3.9-slim

  WORKDIR /app

  # Install runtime dependencies
  RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

  # Copy installed dependencies and app from builder
  COPY --from=backend-build /usr/local /usr/local
  COPY --from=backend-build /app /app

  # Copy pre-built frontend assets
  COPY --from=frontend-build /app/dist /app/client/dist

  # Set environment variables
  ENV PYTHONUNBUFFERED=1

  # Default command is overridden in docker-compose.yml via `command`
  CMD ["gunicorn", "-b", "0.0.0.0:5000", "redash.wsgi:app"]
