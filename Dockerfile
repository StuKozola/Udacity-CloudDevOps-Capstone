# Dockerfile used to package mlflow server

# Base image
FROM python:3.8.10-slim

# Install dependencies for mlflow, sqlalchemy, and aws cli
RUN pip install --no-cache-dir mlflow[extras]==1.14.1 && \
    pip install --no-cache-dir psycopg2-binary==2.8.6 && \
    pip install --no-cache-dir boto3==1.17.40

# Expose port(s)
EXPOSE 5000

# Define startup entrypoint
ENTRYPOINT ["mlflow","server"]