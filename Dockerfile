# Stage 1: Build frontend assets
FROM node:18-alpine as frontend-build

WORKDIR /app

# Install dependencies for building frontend
RUN apk add --no-cache git

# Clone Redash repo (pin to stable tag)
RUN git clone --depth 1 https://github.com/getredash/redash.git .

WORKDIR /app/redash

# Install frontend deps and build
RUN npm install --legacy-peer-deps
RUN npm run build

# Stage 2: Build backend image
FROM python:3.10-slim-buster

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libffi-dev \
    libpq-dev \
    libssl-dev \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create redash user
RUN useradd -m redash

WORKDIR /app

# Copy backend source code from frontend-build stage
COPY --from=frontend-build /app/redash /app

# Copy built frontend assets
COPY --from=frontend-build /app/redash/client/dist /app/client/dist

# Switch to redash user
USER redash

# Upgrade pip and install python deps
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Expose default port
EXPOSE 5000

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# Default to server
CMD ["server"]
