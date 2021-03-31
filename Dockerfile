# Dockerfile used to package mlflow server

# Base image
FROM python:3.8.2-slim

# Install dependencies for mlflow, sqlalchemy, and aws cli
RUN pip install --no-cache-dir mlflow[extras]==1.14.1 && \
    pip install psycopg2-binary==2.8.6 && \
    pip install boto3==1.17.40

# Expose port(s)
EXPOSE 5000

# Define startup entrypoint
ENTRYPOINT ["mlflow","server"]