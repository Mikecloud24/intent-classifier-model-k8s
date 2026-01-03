# use official Python runtime as a parent image
FROM python:3.11-slim

# Prevent Python from writing .pyc files and enable stdout/stderr flushing
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app 

# Install system dependencies (if needed) and Python dependencies
COPY requirements.txt .
RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc libc-dev \
 && pip install --no-cache-dir -r requirements.txt \
 && apt-get remove -y gcc libc-dev \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

 # Copy app code and model project files
 COPY . .

 # Train the model (if applicable) or run any setup scripts
 RUN python3 model/train.py 

 # Expose the port the app runs on
 EXPOSE 6000

 # Start the app with gunicorn (4 workers, bind to 0.0.0.0:6000)
CMD ["gunicorn", "--workers", "4", "--bind", "0.0.0.0:6000", "app:app"]
