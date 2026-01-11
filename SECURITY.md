# Security Configuration Guide

This document outlines the security improvements implemented in the Docker Compose configuration.

## 🔒 Security Issues Fixed

### 1. ✅ Development Volumes Removed from Production

**Problem**: Source code was mounted in production (`docker-compose.yml`), exposing application code and allowing unauthorized modifications.

**Solution**:
- Production (`docker-compose.yml`): Code is baked into Docker images, no source volumes
- Development (`docker-compose.dev.yml`): Source volumes only available in dev mode

```bash
# Production (secure)
npm run start:prod

# Development (with hot-reload)
npm run dev
```

### 2. ✅ Resource Limits Added

**Problem**: No CPU or memory limits could lead to resource exhaustion attacks.

**Solution**: All services now have resource limits and reservations:

| Service  | CPU Limit | Memory Limit | CPU Reserved | Memory Reserved |
|----------|-----------|--------------|--------------|-----------------|
| postgres | 1.0       | 512M         | 0.5          | 256M            |
| redis    | 0.5       | 256M         | 0.25         | 128M            |
| backend  | 2.0       | 1G           | 1.0          | 512M            |
| frontend | 1.0       | 512M         | 0.5          | 256M            |
| nginx    | 0.5       | 256M         | 0.25         | 128M            |

### 3. ✅ Log Rotation Configured

**Problem**: Unlimited log growth could fill disk space.

**Solution**: JSON file logging with rotation:
- Backend: 50MB per file, 5 files max
- Frontend: 25MB per file, 3 files max
- Nginx: 25MB per file, 5 files max
- Database/Redis: 10MB per file, 3 files max

### 4. ✅ Healthcheck Fixed

**Problem**: Healthchecks used `curl` which isn't installed in Alpine Linux images.

**Solution**: Changed to `wget` which is available in Alpine:
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8000/api/health"]
```

### 5. ✅ Nginx Reverse Proxy Added

**Problem**: Services exposed ports directly, no rate limiting, no security headers.

**Solution**: Nginx reverse proxy with:
- Rate limiting (10 req/s for API, 5 req/min for login)
- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- SSL/TLS ready configuration
- Request buffering and timeout controls
- Static asset caching

### 6. ✅ Environment Variables Centralized

**Problem**: Environment variables scattered between compose file and missing .env.

**Solution**:
- Created `.env.example` template
- Documented all configuration options
- Sensitive values remain in `secrets/` directory

### 7. ✅ Secrets Management Improved

**Problem**: While using Docker secrets correctly, password exposure still possible through environment strings.

**Solution**:
- All passwords stored in `secrets/*.txt` files
- Docker secrets mounted at runtime
- `.gitignore` prevents accidental commits
- Documentation in `secrets/README.md`

### 8. ✅ Port Exposure Limited

**Problem**: All services exposed ports to host, increasing attack surface.

**Solution** (Production):
- PostgreSQL: Port removed (access through backend only)
- Redis: Port removed (access through backend only)
- Backend: Port removed (access through Nginx only)
- Frontend: Port removed (access through Nginx only)
- Nginx: Only ports 80 and 443 exposed

**Development Mode** still exposes ports for debugging.

## 🚀 Deployment Modes

### Production Deployment

```bash
# 1. Set up secrets
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/redis_password.txt
openssl rand -base64 48 > secrets/jwt_secret.txt
chmod 600 secrets/*.txt

# 2. Configure environment
cp .env.example .env
# Edit .env with your values

# 3. Start services
npm run start:prod

# 4. Check health
npm run health
```

### Development Deployment

```bash
# 1. Set up secrets (same as production)

# 2. Start with dev overrides
npm run dev

# Services now have:
# - Source code mounted for hot-reload
# - Ports exposed directly for debugging
# - Debug logging enabled
# - No Nginx (direct access)
```

## 🔐 Security Checklist

Before deploying to production:

- [ ] Generate strong, unique secrets
- [ ] Configure `.env` file with production values
- [ ] Set up SSL certificates in `nginx/ssl/`
- [ ] Enable HTTPS in `nginx/conf.d/default.conf`
- [ ] Review and adjust resource limits for your server
- [ ] Configure backup schedule
- [ ] Set up monitoring and alerting
- [ ] Review Nginx security headers
- [ ] Configure firewall rules
- [ ] Enable Docker content trust
- [ ] Set up log aggregation
- [ ] Configure intrusion detection
- [ ] Review rate limiting rules
- [ ] Set up automated security scanning

## 🛡️ Additional Security Recommendations

### 1. SSL/TLS Configuration

Uncomment HTTPS server block in `nginx/conf.d/default.conf` and obtain certificates:

```bash
# Let's Encrypt (free)
certbot certonly --webroot -w /var/www/html -d your-domain.com

# Or generate self-signed for testing
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem
```

### 2. Docker Security

```bash
# Enable Docker Content Trust
export DOCKER_CONTENT_TRUST=1

# Scan images for vulnerabilities
docker scan gemini-mail-backend:latest
docker scan gemini-mail-frontend:latest
```

### 3. Network Security

- Use Docker's internal network (already configured)
- Consider Docker Swarm secrets for production
- Set up firewall rules (UFW/iptables)
- Enable fail2ban for brute-force protection

### 4. Application Security

- Keep dependencies updated
- Run security audits: `npm audit`
- Enable OWASP security headers
- Implement CSRF protection
- Use prepared statements for SQL queries
- Sanitize user input
- Implement proper authentication/authorization

### 5. Monitoring

- Set up Prometheus + Grafana for metrics
- Configure centralized logging (ELK stack)
- Enable security event monitoring
- Set up alerts for suspicious activity

## 📚 References

- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Nginx Security](https://www.nginx.com/blog/nginx-security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

## 🐛 Reporting Security Issues

If you discover a security vulnerability, please email security@your-domain.com instead of using the issue tracker.
