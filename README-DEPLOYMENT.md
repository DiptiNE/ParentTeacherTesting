# Quick Deployment Guide

## 🚀 Quick Start

### Prerequisites
- AWS Account
- EC2 Instance with Docker installed
- Your existing MSSQL database credentials

### 1. Clone and Setup
```bash
git clone <your-repository-url>
cd Cdac_final_project-main
```

### 2. Configure Database Connection
Edit `Backend/ParentTeacherBridge.API/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=your-mssql-server,1433;Initial Catalog=ParentTeacherHub;User ID=your-username;Password=your-password;TrustServerCertificate=true;Encrypt=false"
  }
}
```

### 3. Configure Frontend API URL
Edit `frontend/env.production`:
```
NEXT_PUBLIC_API_URL=http://your-ec2-public-ip:5000
```

### 4. Deploy
```bash
chmod +x deploy.sh
./deploy.sh
```

## 📋 Manual Deployment Steps

### Option A: Using Docker Compose (Recommended)
```bash
# Build and start all services
docker-compose up -d --build

# Check status
docker ps

# View logs
docker-compose logs -f
```

### Option B: Individual Containers
```bash
# Build backend
cd Backend/ParentTeacherBridge.API
docker build -t parent-teacher-backend .

# Build frontend
cd ../../frontend
docker build -t parent-teacher-frontend .

# Run backend
docker run -d -p 5000:80 --name backend parent-teacher-backend

# Run frontend
docker run -d -p 3000:3000 --name frontend parent-teacher-frontend
```

## 🔧 Configuration Files

### Backend Configuration
- `Backend/ParentTeacherBridge.API/appsettings.json` - Database connection
- `Backend/ParentTeacherBridge.API/appsettings.Production.json` - Production settings

### Frontend Configuration
- `frontend/env.production` - API URL and environment variables

### Docker Configuration
- `docker-compose.yml` - Service orchestration
- `Backend/ParentTeacherBridge.API/Dockerfile` - Backend container
- `frontend/Dockerfile` - Frontend container (already exists)

## 🌐 Access Points

- **Frontend**: `http://your-ec2-ip:3000`
- **Backend API**: `http://your-ec2-ip:5000`
- **Swagger UI**: `http://your-ec2-ip:5000/swagger`

## 🛠️ Useful Commands

```bash
# View running containers
docker ps

# View logs
docker logs backend
docker logs frontend

# Restart services
docker-compose restart

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Access container shell
docker exec -it backend /bin/bash
docker exec -it frontend /bin/sh
```

## 🔍 Troubleshooting

### Database Connection Issues
1. Verify MSSQL server is accessible from EC2
2. Check connection string format
3. Ensure firewall allows port 1433
4. Test connection: `telnet your-mssql-server 1433`

### Container Issues
1. Check logs: `docker logs container-name`
2. Verify Dockerfile syntax
3. Check for port conflicts
4. Ensure sufficient disk space

### Frontend API Issues
1. Verify `NEXT_PUBLIC_API_URL` environment variable
2. Check CORS configuration in backend
3. Ensure backend is running and accessible

## 📊 Monitoring

```bash
# Monitor resource usage
docker stats

# View real-time logs
docker-compose logs -f

# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 🔒 Security Checklist

- [ ] Use strong database passwords
- [ ] Configure security groups properly
- [ ] Enable SSL/TLS for database connections
- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Use environment variables for sensitive data

## 💰 Cost Optimization

- Use t2.micro for development (free tier)
- Use t2.small or larger for production
- Monitor CloudWatch metrics
- Set up billing alerts
- Use reserved instances for production

## 📞 Support

For detailed deployment instructions, see `aws-deployment-guide.md`
