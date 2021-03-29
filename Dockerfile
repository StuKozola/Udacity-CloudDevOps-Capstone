# Dockerfile used to package mlflow

# Base image
FROM python:3.8.2-slim

# Create a working directory
#WORKDIR /app

# copy source files to working directory

# Install dependencies for mlflow
RUN pip install mlflow[extras]

# Expose port(s)
EXPOSE 5000

# Define startup entrypoint
ENTRYPOINT ["mlflow","server"]