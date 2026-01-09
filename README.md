# Intent Classifier Model - Kubernetes Deployment

A production-ready machine learning service for intent classification built with Python Flask and deployed on Amazon EKS (Elastic Kubernetes Service). This project demonstrates best practices for containerizing ML models and orchestrating them with Kubernetes.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Local Development](#local-development)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [API Documentation](#api-documentation)
- [Model Training](#model-training)
- [Production Considerations](#production-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This project provides a scalable, containerized intent classification model service. It uses scikit-learn for machine learning and Flask for the REST API, making it easy to deploy on Kubernetes for distributed inference at scale.

**Status**: ✅ Tested and verified on AWS EKS

## Features

- 🚀 **REST API** - Simple HTTP endpoints for health checks and predictions
- 🐳 **Docker Support** - Multi-stage optimized Docker image
- ☸️ **Kubernetes Ready** - Complete K8s manifests (Deployment, Service, Ingress, Namespace)
- 🔄 **Auto-scaling** - Easily scale replicas in Kubernetes
- 🔍 **Health Checks** - Built-in health endpoint for liveness probes
- 📊 **Scikit-learn Model** - Pre-trained intent classification pipeline
- ⚡ **Gunicorn WSGI** - Production-grade application server with multiple workers

## Architecture

```
┌─────────────────┐
│   Client        │
└────────┬────────┘
         │
    ┌────▼────────────┐
    │  Ingress (ALB)  │  AWS ALB with Traefik
    └────┬────────────┘
         │
    ┌────▼──────────────┐
    │  Service          │  ClusterIP/NodePort
    │  (NodePort)       │
    └────┬──────────────┘
         │
    ┌────▼──────────────────────────┐
    │   Deployment Pod (x2)          │
    │  ┌──────────────────────────┐ │
    │  │ Flask + Gunicorn         │ │
    │  │ Port: 6000               │ │
    │  │ (Intent Classifier Model)│ │
    │  └──────────────────────────┘ │
    └───────────────────────────────┘
```

## Prerequisites

### For Local Development
- Python 3.11+
- pip/pipenv
- Git

### For Docker
- Docker 20.10+

### For Kubernetes
- AWS EKS cluster (or any Kubernetes 1.20+)
- `kubectl` CLI configured with cluster access
- Docker registry credentials (for image push/pull)
- Traefik or other ingress controller installed

### Required AWS Resources
- EKS Cluster with at least 2 worker nodes
- AWS Application Load Balancer (ALB) for ingress
- Container Registry (ECR or DockerHub) for image storage

## Project Structure

```
intent-classifier-model-k8s/
├── app.py                 # Flask application entry point
├── wsgi.py               # WSGI application object
├── Dockerfile            # Container image definition
├── requirements.txt      # Python dependencies
├── README.md             # This file
├── model/
│   ├── intent_model.py   # Model inference class
│   ├── train.py          # Model training script
│   └── artifacts/        # Pre-trained model storage
│       └── intent_model.pkl
└── k8s-manifests/        # Kubernetes resources
    ├── namespace.yaml    # intent-namespace
    ├── deployment.yaml   # Pod deployment (2 replicas)
    ├── service.yaml      # NodePort service
    └── ingress.yaml      # Traefik ingress configuration
```

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd intent-classifier-model-k8s
```

### 2. Local Testing (Optional)
```bash
# Install dependencies
pip install -r requirements.txt

# Run the Flask app
python app.py
```

The API will be available at `http://localhost:6000`

### 3. Build Docker Image
```bash
docker build -t mlops-intent-classifier-model:latest .
```

### 4. Deploy to EKS
```bash
# Create namespace and deploy
kubectl apply -f k8s-manifests/namespace.yaml
kubectl apply -f k8s-manifests/deployment.yaml
kubectl apply -f k8s-manifests/service.yaml
kubectl apply -f k8s-manifests/ingress.yaml

# Verify deployment
kubectl get pods -n intent-namespace
```

## Local Development

### Setup Environment
```bash
# Create virtual environment
python -m venv venv

# Activate environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Run Flask Application
```bash
# Development mode (hot reload)
python app.py

# Production mode with gunicorn
gunicorn --workers 4 --bind 0.0.0.0:6000 app:app
```

### Train the Model
```bash
python model/train.py
```

This script trains/updates the intent classification model and saves it to `model/artifacts/intent_model.pkl`.

## Docker Deployment

### Build Image
```bash
docker build -t mlops-intent-classifier-model:latest .
```

### Run Container Locally
```bash
docker run -p 6000:6000 mlops-intent-classifier-model:latest
```

### Push to Registry
```bash
# For DockerHub
docker tag mlops-intent-classifier-model:latest <username>/mlops-intent-classifier-model:latest
docker push <username>/mlops-intent-classifier-model:latest

# For AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker tag mlops-intent-classifier-model:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/mlops-intent-classifier-model:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/mlops-intent-classifier-model:latest
```

## Kubernetes Deployment

### Prerequisites
Ensure Traefik ingress controller is installed:
```bash
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik-helm-chart/master/traefik/Chart.yaml
```

### Deploy All Resources
```bash
# Apply all manifests
kubectl apply -f k8s-manifests/

# Verify deployment
kubectl get all -n intent-namespace
```

### Verify Deployment
```bash
# Check pod status
kubectl get pods -n intent-namespace

# Check service
kubectl get svc -n intent-namespace

# Check ingress
kubectl get ingress -n intent-namespace

# View pod logs
kubectl logs -n intent-namespace -l app=intent-classifier -f
```

### Scale Replicas
```bash
# Scale to 5 replicas
kubectl scale deployment intent-classifier -n intent-namespace --replicas=5

# Auto-scale with HPA (Optional)
kubectl autoscale deployment intent-classifier -n intent-namespace --min=2 --max=10 --cpu-percent=80
```

### Update Deployment
```bash
# Update image (e.g., new version)
kubectl set image deployment/intent-classifier \
  -n intent-namespace \
  intent-classifier=<new-image>:<new-tag>

# Monitor rollout
kubectl rollout status deployment/intent-classifier -n intent-namespace
```

## API Documentation

### Health Check Endpoint
**GET** `/health`

Returns the service health status.

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

**Example:**
```bash
curl http://localhost:6000/health
```

### Prediction Endpoint
**POST** `/predict`

Classifies the intent of the provided text.

**Request Body:**
```json
{
  "text": "Can you help me reset my password?"
}
```

**Response (200 OK):**
```json
{
  "intent": "password_reset"
}
```

**Example:**
```bash
curl -X POST http://localhost:6000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "Can you help me reset my password?"}'
```

**Error Response (400 Bad Request):**
```json
{
  "error": "Missing 'text' parameter"
}
```

### Testing with EKS Ingress

Once deployed on EKS, update the domain in `k8s-manifests/ingress.yaml`:

```yaml
rules:
  - host: your-domain.com  # Change this
    http:
      paths:
        - path: /predict
          backend:
            service:
              name: intent-classifier
              port:
                number: 80
```

Then test:
```bash
curl https://your-domain.com/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I need help with my account"}'
```

## Model Training

The model is trained during Docker image build (see `Dockerfile`):

```dockerfile
RUN python3 model/train.py
```

To retrain locally:
```bash
python model/train.py
```

**Model Details:**
- Framework: scikit-learn
- Input: Text (string)
- Output: Intent classification
- Storage: `model/artifacts/intent_model.pkl`
- Format: joblib serialized object

To use a different model, replace `intent_model.pkl` and update the `IntentModel` class in [model/intent_model.py](model/intent_model.py).

## Production Considerations

### Resource Limits
Add resource requests/limits in [k8s-manifests/deployment.yaml](k8s-manifests/deployment.yaml):

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Environment Variables
Configure via `configMap` or `secret`:

```yaml
env:
  - name: FLASK_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "INFO"
```

### Monitoring & Logging
- **Application Logs**: Use `kubectl logs` or CloudWatch Logs
- **Metrics**: Implement Prometheus metrics in Flask app
- **Tracing**: Consider OpenTelemetry integration
- **Monitoring Stack**: Deploy Prometheus + Grafana for metrics visualization

### Security
- Use private Docker registry
- Enable Pod Security Policies
- Use network policies to restrict traffic
- Implement RBAC for Kubernetes access
- Use secrets for sensitive data (API keys, credentials)

### CI/CD Integration
Implement a pipeline to:
1. Build Docker image on code push
2. Run tests
3. Push to registry
4. Deploy to staging/production clusters
5. Run smoke tests

## Troubleshooting

### Pod Not Starting
```bash
# Check pod status and events
kubectl describe pod -n intent-namespace <pod-name>

# View logs
kubectl logs -n intent-namespace <pod-name>
```

### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints -n intent-namespace

# Test service connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://intent-classifier.intent-namespace.svc.cluster.local/health
```

### Image Pull Errors
```bash
# Verify image exists in registry
docker images | grep intent-classifier

# Check image pull secrets
kubectl get secrets -n intent-namespace
```

### Ingress Not Working
```bash
# Verify ingress controller
kubectl get pods -n kube-system | grep traefik

# Check ingress configuration
kubectl describe ingress -n intent-namespace

# Check service type (should be ClusterIP or NodePort)
kubectl get svc -n intent-namespace
```

### High Latency
- Check resource utilization: `kubectl top pods -n intent-namespace`
- Scale up replicas for better load distribution
- Monitor Gunicorn worker count and connections

## Contributing

1. Create a feature branch
2. Make changes and test locally
3. Build and test Docker image
4. Submit pull request with description
5. Ensure all tests pass in CI/CD


## Support

For issues and questions:
- Open a GitHub issue
- Check existing documentation
- Review Kubernetes logs with `kubectl logs`

---

**Last Updated**: January 2026  
**Status**: Production Ready on EKS ✅
