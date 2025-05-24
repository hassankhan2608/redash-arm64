FROM python:3.9-slim-buster

RUN apt-get update && apt-get install -y     build-essential     libffi-dev     libssl-dev     libpq-dev     && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["./bin/run-server"]
