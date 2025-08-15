# AWS Deployment Guide for CDAC Final Project

This guide provides detailed steps to deploy your Parent-Teacher Bridge application on AWS using EC2, Docker, and connect to your existing MSSQL database.

## Prerequisites

1. AWS Account with appropriate permissions
2. AWS CLI installed and configured
3. Docker installed locally for testing
4. Your existing MSSQL database credentials
5. Domain name (optional, for production)

## Option 1: Deploy with RDS (Recommended for Production)

### Step 1: Create RDS SQL Server Instance

1. **Login to AWS Console**
   - Go to AWS RDS Console
   - Click "Create database"

2. **Choose database creation method**
   - Select "Standard create"
   - Choose "Microsoft SQL Server"
   - Select "SQL Server Express" (free tier) or "SQL Server Standard" (production)

3. **Configure database settings**
   - DB instance identifier: `parent-teacher-db`
   - Master username: `admin`
   - Master password: `YourStrongPassword123!`
   - Instance size: `db.t3.micro` (free tier) or larger for production

4. **Configure connectivity**
   - VPC: Create new VPC or use default
   - Public access: Yes (for external connection)
   - VPC security group: Create new
   - Availability Zone: Choose closest to your region
   - Database port: 1433

5. **Configure additional settings**
   - Initial database name: `ParentTeacherHub`
   - Backup retention: 7 days
   - Enable automated backups

6. **Click "Create database"**

### Step 2: Create EC2 Instance

1. **Launch EC2 Instance**
   - Go to EC2 Console
   - Click "Launch Instance"

2. **Configure instance**
   - Name: `parent-teacher-app`
   - AMI: Amazon Linux 2023
   - Instance type: `t2.micro` (free tier) or `t2.small` (recommended)
   - Key pair: Create new or use existing

3. **Configure security group**
   - Allow SSH (port 22) from your IP
   - Allow HTTP (port 80) from anywhere
   - Allow HTTPS (port 443) from anywhere
   - Allow custom TCP (port 3000) from anywhere (for frontend)
   - Allow custom TCP (port 5000) from anywhere (for backend)

4. **Launch instance**

### Step 3: Configure EC2 Instance

1. **Connect to EC2 instance**
   ```bash
   ssh -i your-key.pem ec2-user@your-ec2-public-ip
   ```

2. **Update system and install Docker**
   ```bash
   sudo yum update -y
   sudo yum install -y docker git
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -a -G docker ec2-user
   ```

3. **Install Docker Compose**
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   ```

4. **Logout and login again to apply docker group changes**
   ```bash
   exit
   ssh -i your-key.pem ec2-user@your-ec2-public-ip
   ```

### Step 4: Deploy Application

1. **Clone your project**
   ```bash
   git clone <your-repository-url>
   cd Cdac_final_project-main
   ```

2. **Update connection string for RDS**
   - Edit `Backend/ParentTeacherBridge.API/appsettings.json`
   - Replace the connection string with your RDS endpoint:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Data Source=your-rds-endpoint.region.rds.amazonaws.com,1433;Initial Catalog=ParentTeacherHub;User ID=admin;Password=YourStrongPassword123!;TrustServerCertificate=true;Encrypt=false"
     }
   }
   ```

3. **Update frontend API URL**
   - Edit `frontend/.env.local` or create it:
   ```
   NEXT_PUBLIC_API_URL=http://your-ec2-public-ip:5000
   ```

4. **Build and run with Docker Compose**
   ```bash
   docker-compose up -d --build
   ```

5. **Check if containers are running**
   ```bash
   docker ps
   docker logs backend
   docker logs frontend
   ```

### Step 5: Configure Domain and SSL (Optional)

1. **Set up Application Load Balancer**
   - Create ALB in AWS Console
   - Configure target groups for ports 3000 and 5000
   - Set up SSL certificate with ACM

2. **Configure Route 53**
   - Create hosted zone for your domain
   - Create A record pointing to ALB

## Option 2: Deploy without RDS (Using Existing MSSQL Database)

### Step 1: Configure Security for External Database

1. **Update your existing MSSQL server**
   - Enable TCP/IP protocol
   - Configure firewall to allow AWS EC2 IP
   - Create database user with appropriate permissions

2. **Get your database connection details**
   - Server IP/domain
   - Database name: `ParentTeacherHub`
   - Username and password
   - Port: 1433

### Step 2: Create EC2 Instance (Same as above)

### Step 3: Deploy Application

1. **Clone and configure project**
   ```bash
   git clone <your-repository-url>
   cd Cdac_final_project-main
   ```

2. **Update connection string for your existing database**
   - Edit `Backend/ParentTeacherBridge.API/appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Data Source=your-mssql-server-ip,1433;Initial Catalog=ParentTeacherHub;User ID=your-username;Password=your-password;TrustServerCertificate=true;Encrypt=false"
     }
   }
   ```

3. **Create production docker-compose file**
   ```bash
   cp docker-compose.yml docker-compose.prod.yml
   ```

4. **Edit docker-compose.prod.yml**:
   ```yaml
   version: '3.8'
   
   services:
     backend:
       build:
         context: ./Backend/ParentTeacherBridge.API
         dockerfile: Dockerfile
       ports:
         - "5000:80"
       environment:
         - ASPNETCORE_ENVIRONMENT=Production
         - ConnectionStrings__DefaultConnection=Data Source=your-mssql-server-ip,1433;Initial Catalog=ParentTeacherHub;User ID=your-username;Password=your-password;TrustServerCertificate=true;Encrypt=false
       networks:
         - app-network
   
     frontend:
       build:
         context: ./frontend
         dockerfile: Dockerfile
       ports:
         - "3000:3000"
       environment:
         - NODE_ENV=production
         - NEXT_PUBLIC_API_URL=http://your-ec2-public-ip:5000
       depends_on:
         - backend
       networks:
         - app-network
   
   networks:
     app-network:
       driver: bridge
   ```

5. **Deploy the application**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d --build
   ```

## Step 6: Testing and Verification

1. **Test backend API**
   ```bash
   curl http://your-ec2-public-ip:5000/swagger
   ```

2. **Test frontend**
   - Open browser: `http://your-ec2-public-ip:3000`

3. **Check application logs**
   ```bash
   docker logs backend
   docker logs frontend
   ```

## Step 7: Monitoring and Maintenance

1. **Set up CloudWatch monitoring**
   - Create CloudWatch dashboard
   - Set up alarms for CPU, memory, and disk usage

2. **Set up automated backups**
   - Configure EBS snapshots
   - Set up database backups

3. **Set up logging**
   ```bash
   # View real-time logs
   docker logs -f backend
   docker logs -f frontend
   ```

## Troubleshooting

### Common Issues:

1. **Database Connection Issues**
   - Verify security group allows port 1433
   - Check connection string format
   - Ensure database server is accessible from EC2

2. **Container Build Issues**
   - Check Dockerfile syntax
   - Verify all dependencies are included
   - Check for port conflicts

3. **Frontend API Connection Issues**
   - Verify NEXT_PUBLIC_API_URL environment variable
   - Check CORS configuration in backend
   - Ensure backend is running and accessible

### Useful Commands:

```bash
# Restart services
docker-compose restart

# View logs
docker-compose logs

# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# Check container status
docker ps -a

# Access container shell
docker exec -it container_name /bin/bash
```

## Security Considerations

1. **Use strong passwords for database**
2. **Configure security groups properly**
3. **Enable SSL/TLS for database connections**
4. **Regular security updates**
5. **Monitor access logs**
6. **Use IAM roles instead of access keys**

## Cost Optimization

1. **Use reserved instances for production**
2. **Right-size your EC2 instances**
3. **Use S3 for static assets**
4. **Enable auto-scaling for traffic spikes**
5. **Monitor and optimize database queries**

## Next Steps

1. Set up CI/CD pipeline with GitHub Actions
2. Configure monitoring and alerting
3. Set up backup and disaster recovery
4. Implement auto-scaling
5. Add CDN for static assets
6. Set up staging environment

This deployment guide covers both RDS and external MSSQL database options. Choose the option that best fits your requirements and budget.
