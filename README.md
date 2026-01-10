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
- [CI/CD Integration](#cicd-integration)
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

This project includes comprehensive GitHub Actions workflows for Continuous Integration and Continuous Deployment. All workflow files are located in [.github/workflows/](.github/workflows/).

#### Continuous Integration (CI.yaml)

Triggered on push/PR to `main` or `develop` branches. Includes:

1. **Code Quality & Linting**
   - Black code formatting
   - isort import sorting
   - Flake8 linting

2. **Unit Tests**
   - pytest with coverage reporting
   - Codecov integration

3. **Model Training & Validation**
   - Trains intent classification model
   - Validates model artifacts
   - Tests predictions end-to-end

4. **Integration Tests**
   - Flask health endpoint test
   - Flask predict endpoint test

5. **Docker Build**
   - Multi-stage Docker build
   - Layer caching optimization

6. **Test Summary**
   - Comprehensive reporting
   - Pipeline status checks

**Triggers:**
```yaml
- Push to main/develop branches
- Pull requests to main/develop
- Changes to: model/*, requirements.txt, app.py, wsgi.py
```

#### Continuous Deployment (CD.yaml)

Triggered on:
- Push to `main` branch (production deployment)
- Workflow dispatch (manual trigger for staging/production)
- Completion of CI workflow

**Jobs:**

1. **Prepare Deployment**
   - Determines target environment (staging/production)
   - Generates image tags with build number, commit SHA, latest

2. **Build & Push Docker Image**
   - Builds optimized multi-stage image
   - Pushes to Docker Hub with multiple tags
   - Caches layers for faster builds

3. **Security Scan**
   - Trivy vulnerability scanning
   - Python dependencies scanning (Safety)
   - SARIF report uploaded to GitHub Security tab

4. **Deploy to EKS**
   - Configures AWS credentials
   - Updates kubeconfig
   - Rolls out new image to EKS cluster
   - Verifies deployment status

5. **Smoke Tests**
   - Port forwarding to service
   - Health endpoint verification
   - Prediction endpoint verification
   - Pod resource usage check

6. **Verify Deployment**
   - Confirms deployment availability
   - Checks ready replicas
   - Exports deployment info and logs

7. **Notifications**
   - Optional Slack notifications
   - GitHub summary reporting

#### Setting Up CI/CD

##### 1. Add Required GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions, and add:

```
DOCKERHUB_USERNAME          # Your Docker Hub username
DOCKERHUB_TOKEN             # Docker Hub personal access token
AWS_ACCESS_KEY_ID           # AWS IAM access key
AWS_SECRET_ACCESS_KEY       # AWS IAM secret key
SLACK_WEBHOOK_URL           # (Optional) Slack webhook for notifications
```

**Creating Docker Hub Token:**
```bash
# Visit https://hub.docker.com/settings/security
# Create a new access token
# Use this token as DOCKERHUB_TOKEN
```

**Creating AWS IAM User:**
```bash
# Create IAM user with permissions for EKS and ECR
# Required policies:
# - AmazonEKSFullAccess
# - AmazonEC2ContainerRegistryFullAccess
# - IAMReadOnlyAccess (for credential validation)

# Generate access key from AWS Console
# Save as AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

**GitHub Environment Configuration (Optional):**

For separate staging/production environments, configure:

1. Go to Settings → Environments
2. Create `staging` and `production` environments
3. Add deployment protection rules and required reviewers (for production)

##### 2. Update Deployment Configuration

Edit [k8s-manifests/deployment.yaml](k8s-manifests/deployment.yaml) to match your setup:

```yaml
metadata:
  name: intent-classifier
  namespace: intent-namespace  # Change if needed
spec:
  replicas: 2  # Adjust as needed
  template:
    spec:
      containers:
        - name: intent-classifier
          image: your-registry/mlops-intent-classifier-model:latest
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

##### 3. Update Environment Variables in CD.yaml

Edit [.github/workflows/CD.yaml](.github/workflows/CD.yaml) to configure:

```yaml
env:
  REGISTRY: docker.io                          # Change if using ECR
  IMAGE_NAME: your-username/image-name         # Your registry image
  AWS_REGION: us-east-1                        # Your AWS region
  EKS_CLUSTER_NAME: intent-classifier-cluster  # Your EKS cluster name
  K8S_NAMESPACE: intent-namespace              # Your namespace
```

#### Running CI/CD Workflows

##### CI Pipeline

Automatically triggered on:
```bash
# Push code changes
git add .
git commit -m "feat: update model training"
git push origin develop

# Or create a pull request
```

View results:
- Go to repository → Actions tab
- Click on the workflow run
- Review logs for each job

##### CD Pipeline - Production Deployment

**Option 1: Automatic (on main branch push)**
```bash
git add .
git commit -m "release: version 1.0.0"
git push origin main  # Triggers CD automatically for production
```

**Option 2: Manual Trigger**
1. Go to repository → Actions
2. Select "CD - Deploy to EKS" workflow
3. Click "Run workflow"
4. Select environment: `staging` or `production`
5. Click "Run workflow"

##### Monitoring Deployments

```bash
# View pods
kubectl get pods -n intent-namespace

# View deployment status
kubectl get deployment -n intent-namespace -o wide

# Stream logs
kubectl logs -n intent-namespace -l app=intent-classifier -f

# Check rollout status
kubectl rollout status deployment/intent-classifier -n intent-namespace
```

#### Troubleshooting CI/CD

**CI Pipeline Fails:**
```bash
# Check logs in GitHub Actions
# Common issues:
# - Python version mismatch: Ensure Python 3.11 is used
# - Dependency issues: Run `pip install -r requirements.txt` locally
# - Test failures: Run `pytest tests/` locally to debug
```

**CD Deployment Fails:**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify EKS cluster access
aws eks describe-cluster --name intent-classifier-cluster --region us-east-1

# Check Docker Hub authentication
docker login  # Verify credentials

# Review pod logs for deployment errors
kubectl describe pod -n intent-namespace <pod-name>
kubectl logs -n intent-namespace <pod-name>
```

**Image Pull Errors:**
```bash
# Verify image exists in Docker Hub
docker pull your-username/mlops-intent-classifier-model:latest

# Check image pull secrets in cluster
kubectl get secrets -n intent-namespace
```

#### Best Practices

1. **Always test locally before pushing:**
   ```bash
   python -m pytest tests/
   docker build -t test-image:latest .
   docker run -p 6000:6000 test-image:latest
   ```

2. **Use semantic versioning:**
   - Tag releases: `git tag v1.0.0`
   - Push tags: `git push origin --tags`

3. **Review security scan results:**
   - GitHub Security tab shows Trivy vulnerabilities
   - Fix high/critical vulnerabilities before deployment

4. **Monitor resource usage:**
   ```bash
   kubectl top pods -n intent-namespace
   kubectl top nodes
   ```

5. **Keep secrets secure:**
   - Never commit credentials
   - Rotate tokens regularly
   - Use separate AWS IAM users for CI/CD

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
