# Deployment Guide - Gemini Mail Enterprise

This guide covers deployment for both development and production environments.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Development Setup](#development-setup)
- [Production Deployment](#production-deployment)
- [Security Configuration](#security-configuration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker 20.10+ installed
- Docker Compose 2.0+ installed
- Node.js 20.x (for local development)
- OpenSSL (for generating secrets)
- 4GB+ RAM available
- 20GB+ disk space

## Quick Start

### 1. Clone and Setup

```bash
# Clone repository
git clone <repository-url>
cd gemini-mail-enterprise

# Generate secrets
./setup-secrets.sh

# Configure environment
cp .env.example .env
# Edit .env with your values
```

### 2. Choose Your Mode

**Development (with hot-reload):**
```bash
npm run dev
```

**Production:**
```bash
npm run start:prod
```

## Development Setup

Development mode includes:
- Source code mounted for hot-reload
- Direct port exposure for debugging
- Debug logging enabled
- No Nginx reverse proxy
- Lower resource limits

### Start Development Environment

```bash
# Build and start with dev overrides
npm run dev:build

# Or just start if already built
npm run dev

# View logs
npm run logs

# Stop
npm run stop
```

### Exposed Ports (Development)

| Service    | Port  | URL                      |
|------------|-------|--------------------------|
| Frontend   | 8173  | http://localhost:8173    |
| Backend    | 7098  | http://localhost:7098    |
| PostgreSQL | 15432 | localhost:15432          |
| Redis      | 16379 | localhost:16379          |

### Development Commands

```bash
# Run backend tests
npm run test

# Run frontend tests
npm run test:frontend

# Run database migrations
npm run migrate

# Seed database
npm run seed

# Clean everything (including volumes)
npm run clean:dev
```

## Production Deployment

Production mode includes:
- Code baked into Docker images (no source mounts)
- Nginx reverse proxy with SSL/TLS
- Rate limiting and security headers
- Full resource limits
- Log rotation configured
- No direct port exposure

### 1. Prepare Secrets

```bash
# Generate all secrets
./setup-secrets.sh

# Or manually:
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/redis_password.txt
openssl rand -base64 48 > secrets/jwt_secret.txt
chmod 600 secrets/*.txt
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with production values:

```bash
NODE_ENV=production
LOG_LEVEL=info

VITE_API_URL=https://your-domain.com/api
VITE_APP_NAME=Gemini Mail Enterprise

ADMIN_USERNAME=admin
ADMIN_EMAIL=admin@your-domain.com

# Backup configuration
BACKUP_ENABLED=true
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=7
```

### 3. Set Up SSL/TLS (Required for Production)

**Option A: Let's Encrypt (Recommended)**

```bash
# Install certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d your-domain.com

# Copy to nginx directory
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem nginx/ssl/key.pem
sudo chmod 644 nginx/ssl/cert.pem
sudo chmod 600 nginx/ssl/key.pem
```

**Option B: Self-Signed (Development/Testing Only)**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
chmod 600 nginx/ssl/key.pem
chmod 644 nginx/ssl/cert.pem
```

### 4. Enable HTTPS in Nginx

Edit `nginx/conf.d/default.conf` and uncomment the HTTPS server block:

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    # ... rest of configuration
}
```

### 5. Build and Deploy

```bash
# Build images (this may take several minutes)
npm run build:prod

# Start services
npm run start:prod

# Check status
npm run health

# View logs
npm run logs
```

### 6. Verify Deployment

```bash
# Check all services are running
docker compose ps

# Test backend health
curl http://localhost/api/health

# Test frontend
curl http://localhost/

# Check Nginx
curl http://localhost/health
```

### Exposed Ports (Production)

| Service | Port | URL                      |
|---------|------|--------------------------|
| Nginx   | 80   | http://your-domain.com   |
| Nginx   | 443  | https://your-domain.com  |

All other services are internal only.

## Security Configuration

### Security Features Enabled

✅ Resource limits on all containers
✅ Log rotation configured
✅ Nginx reverse proxy with rate limiting
✅ Security headers (HSTS, X-Frame-Options, etc.)
✅ Docker secrets for sensitive data
✅ No source code exposure in production
✅ Internal networking only
✅ Healthchecks for all services

### Post-Deployment Security Checklist

- [ ] Change all default credentials
- [ ] Enable HTTPS and force redirect
- [ ] Configure firewall (UFW/iptables)
- [ ] Set up fail2ban for brute-force protection
- [ ] Enable Docker Content Trust
- [ ] Configure backup automation
- [ ] Set up monitoring and alerts
- [ ] Review Nginx rate limits
- [ ] Enable security scanning
- [ ] Configure log aggregation
- [ ] Set up intrusion detection
- [ ] Review SECURITY.md

See [SECURITY.md](SECURITY.md) for detailed security configuration.

## Resource Requirements

### Minimum (Development)

- CPU: 2 cores
- RAM: 4GB
- Disk: 10GB

### Recommended (Production)

- CPU: 4+ cores
- RAM: 8GB+
- Disk: 50GB+ (SSD recommended)
- Network: 100Mbps+

### Resource Limits (Production)

| Service    | CPU Limit | Memory Limit | CPU Reserved | Memory Reserved |
|------------|-----------|--------------|--------------|-----------------|
| postgres   | 1.0       | 512M         | 0.5          | 256M            |
| redis      | 0.5       | 256M         | 0.25         | 128M            |
| backend    | 2.0       | 1G           | 1.0          | 512M            |
| frontend   | 1.0       | 512M         | 0.5          | 256M            |
| nginx      | 0.5       | 256M         | 0.25         | 128M            |
| **Total**  | **5.0**   | **2.5G**     | **2.5**      | **1.3G**        |

## Maintenance

### Backup

```bash
# Manual backup
npm run backup

# Restore from backup
npm run restore
```

### Updates

```bash
# Pull latest images
docker compose pull

# Rebuild and restart
npm run rebuild
npm run restart
```

### Logs

```bash
# View all logs
npm run logs

# View specific service
docker compose logs -f backend

# View last 100 lines
docker compose logs --tail=100
```

### Database Migrations

```bash
# Run migrations
npm run migrate

# Seed database
npm run seed
```

## Troubleshooting

### Services Won't Start

```bash
# Check service status
npm run ps

# View logs for errors
npm run logs

# Check secrets exist
ls -la secrets/

# Verify .env file
cat .env
```

### Port Conflicts

```bash
# Check what's using ports
sudo lsof -i :80
sudo lsof -i :443

# Kill conflicting process
sudo kill -9 <PID>
```

### Permission Issues

```bash
# Fix secret permissions
chmod 600 secrets/*.txt

# Fix SSL permissions
chmod 600 nginx/ssl/key.pem
chmod 644 nginx/ssl/cert.pem
```

### Database Connection Errors

```bash
# Check PostgreSQL logs
docker compose logs postgres

# Verify secret file
cat secrets/db_password.txt

# Connect to database directly
docker compose exec postgres psql -U gemini_user -d gemini_mail
```

### Memory Issues

```bash
# Check Docker resources
docker stats

# Reduce resource limits in docker-compose.yml
# Or increase available memory
```

### Nginx Issues

```bash
# Test Nginx configuration
docker compose exec nginx nginx -t

# Reload Nginx
docker compose exec nginx nginx -s reload

# Check Nginx logs
docker compose logs nginx
```

## Scaling

### Horizontal Scaling

For Docker Swarm:

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml gemini-mail

# Scale services
docker service scale gemini-mail_backend=3
docker service scale gemini-mail_frontend=2
```

### Vertical Scaling

Adjust resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '4.0'      # Increase
      memory: 2G       # Increase
```

## Monitoring

### Health Checks

```bash
# Check service health
docker compose ps

# Manual health check
curl http://localhost/api/health
```

### Metrics

Consider adding:
- Prometheus for metrics collection
- Grafana for visualization
- ELK stack for log aggregation
- Sentry for error tracking

## Support

- Documentation: See README.md
- Security Issues: See SECURITY.md
- Issues: GitHub Issues
- Email: support@your-domain.com

## License

MIT License - See LICENSE file for details
