# Dockerfile used to package mlflow

# Base image
FROM python:3.8.2-slim

# Create a working directory
#WORKDIR /app

# copy source files to working directory

# Install dependencies for mlflow
RUN pip install mlflow[extras]=1.9.1 && \
    pip install psycopg2-binary=2.8.5 && \
    pip install boto3=1.15.16

# Expose port(s)
EXPOSE 5000

# Define startup entrypoint
ENTRYPOINT ["mlflow","server"]