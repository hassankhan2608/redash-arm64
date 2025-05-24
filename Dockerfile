# Use multi-stage build

# --- Stage 1: Clone Redash and build frontend ---
  FROM node:18-bullseye-slim AS frontend-build

  WORKDIR /app

  # Clone official Redash repo (you can change branch/tag here)
  RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

  RUN git clone --depth 1 --branch master https://github.com/getredash/redash.git .

  WORKDIR /app/client

  RUN yarn install --frozen-lockfile

  RUN yarn build


  # --- Stage 2: Backend build ---
  FROM python:3.9-slim-buster AS backend-build

  RUN apt-get update && apt-get install -y \
      build-essential \
      libffi-dev \
      libssl-dev \
      libpq-dev \
      git \
      && rm -rf /var/lib/apt/lists/*

  WORKDIR /app

  # Clone Redash again here for backend
  RUN git clone --depth 1 --branch master https://github.com/getredash/redash.git .

  RUN pip install --no-cache-dir -r requirements.txt

  # --- Stage 3: Final runtime image ---
  FROM python:3.9-slim-buster

  RUN apt-get update && apt-get install -y \
      libpq-dev \
      curl \
      && rm -rf /var/lib/apt/lists/*

  WORKDIR /app

  # Copy backend files from backend-build stage
  COPY --from=backend-build /app /app

  # Copy frontend build from frontend-build stage to client/build folder
  COPY --from=frontend-build /app/client/build /app/client/build

  ENV PYTHONPATH=/app
  ENV REDASH_LOG_LEVEL=INFO
  ENV REDASH_WORKERS_COUNT=4

  EXPOSE 5000

  CMD ["./bin/run-server"]
