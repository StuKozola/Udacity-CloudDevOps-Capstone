# Dockerfile used to package mlflow server

# Base image
FROM python:3.8.2-slim

# Install dependencies for mlflow
RUN pip install --no-cache-dir mlflow[extras]==1.15.0

# Expose port(s)
EXPOSE 5000

# Define startup entrypoint
ENTRYPOINT ["mlflow","server"]