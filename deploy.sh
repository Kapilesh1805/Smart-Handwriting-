#!/bin/bash

# Docker Hub Deployment Script for Handwriting Recognition System
# Usage: ./deploy.sh [build|push|deploy] [tag]

set -e

# Configuration
DOCKER_HUB_USERNAME="kapilesh18"
PROJECT_NAME="handwriting-recognition"
TAG=${2:-"latest"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    echo_info "Docker is running"
}

# Login to Docker Hub
docker_login() {
    echo_info "Logging into Docker Hub..."
    if ! docker login --username "$DOCKER_HUB_USERNAME"; then
        echo_error "Failed to login to Docker Hub. Please check your credentials."
        exit 1
    fi
    echo_info "Successfully logged into Docker Hub"
}

# Build all services
build_services() {
    echo_info "Building all services..."

    # Build ML Service
    echo_info "Building ML Service..."
    docker build -t "$DOCKER_HUB_USERNAME/$PROJECT_NAME-ml:$TAG" -f ml-service/Dockerfile ./ml-service

    # Build Backend
    echo_info "Building Backend..."
    docker build -t "$DOCKER_HUB_USERNAME/$PROJECT_NAME-backend:$TAG" -f Dockerfile.backend .

    # Build Frontend
    echo_info "Building Frontend..."
    docker build -t "$DOCKER_HUB_USERNAME/$PROJECT_NAME-frontend:$TAG" -f Dockerfile.frontend ./handwriting_frontend

    echo_info "All services built successfully"
}

# Push to Docker Hub
push_services() {
    echo_info "Pushing services to Docker Hub..."

    docker push "$DOCKER_HUB_USERNAME/$PROJECT_NAME-ml:$TAG"
    docker push "$DOCKER_HUB_USERNAME/$PROJECT_NAME-backend:$TAG"
    docker push "$DOCKER_HUB_USERNAME/$PROJECT_NAME-frontend:$TAG"

    echo_info "All services pushed to Docker Hub"
}

# Test locally
test_locally() {
    echo_info "Testing services locally..."

    # Start services
    docker-compose up -d

    # Wait for services to be healthy
    echo_info "Waiting for services to start..."
    sleep 30

    # Test health endpoints
    echo_info "Testing ML service..."
    if curl -f http://localhost:8000/health >/dev/null 2>&1; then
        echo_info "ML service is healthy"
    else
        echo_error "ML service health check failed"
    fi

    echo_info "Testing backend..."
    if curl -f http://localhost:5000/health >/dev/null 2>&1; then
        echo_info "Backend is healthy"
    else
        echo_error "Backend health check failed"
    fi

    echo_info "Testing frontend..."
    if curl -f http://localhost:80 >/dev/null 2>&1; then
        echo_info "Frontend is accessible"
    else
        echo_error "Frontend health check failed"
    fi
}

# Main deployment function
main() {
    local command=$1

    check_docker

    case $command in
        "build")
            build_services
            ;;
        "push")
            docker_login
            push_services
            ;;
        "deploy")
            build_services
            docker_login
            push_services
            ;;
        "test")
            test_locally
            ;;
        *)
            echo "Usage: $0 {build|push|deploy|test} [tag]"
            echo "  build  - Build all Docker images"
            echo "  push   - Push images to Docker Hub"
            echo "  deploy - Build and push all images"
            echo "  test   - Test services locally"
            exit 1
            ;;
    esac
}

main "$@"