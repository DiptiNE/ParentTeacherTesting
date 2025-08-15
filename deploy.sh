#!/bin/bash

# AWS EC2 Deployment Script for CDAC Final Project
# This script automates the deployment process

set -e  # Exit on any error

echo "🚀 Starting deployment of CDAC Final Project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install it first."
    exit 1
fi

# Stop existing containers
print_status "Stopping existing containers..."
docker-compose down || true

# Remove old images to free up space
print_status "Cleaning up old Docker images..."
docker system prune -f

# Build and start containers
print_status "Building and starting containers..."
docker-compose up -d --build

# Wait for containers to be ready
print_status "Waiting for containers to be ready..."
sleep 30

# Check if containers are running
print_status "Checking container status..."
if docker ps | grep -q "backend"; then
    print_status "✅ Backend container is running"
else
    print_error "❌ Backend container failed to start"
    docker logs backend
    exit 1
fi

if docker ps | grep -q "frontend"; then
    print_status "✅ Frontend container is running"
else
    print_error "❌ Frontend container failed to start"
    docker logs frontend
    exit 1
fi

# Test backend API
print_status "Testing backend API..."
if curl -f http://localhost:5000/swagger > /dev/null 2>&1; then
    print_status "✅ Backend API is accessible"
else
    print_warning "⚠️  Backend API might not be ready yet. Check logs:"
    docker logs backend
fi

# Test frontend
print_status "Testing frontend..."
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    print_status "✅ Frontend is accessible"
else
    print_warning "⚠️  Frontend might not be ready yet. Check logs:"
    docker logs frontend
fi

# Show container logs
print_status "Container logs:"
echo "=== Backend Logs ==="
docker logs --tail=20 backend
echo ""
echo "=== Frontend Logs ==="
docker logs --tail=20 frontend

# Show final status
print_status "Deployment completed!"
print_status "Frontend: http://localhost:3000"
print_status "Backend API: http://localhost:5000"
print_status "Swagger UI: http://localhost:5000/swagger"

echo ""
print_status "Useful commands:"
echo "  View logs: docker-compose logs -f"
echo "  Stop services: docker-compose down"
echo "  Restart services: docker-compose restart"
echo "  Rebuild: docker-compose up -d --build"
