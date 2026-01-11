# Security Configuration Guide

This document outlines the comprehensive security improvements implemented in the Docker Compose configuration and Docker images.

## 🛡️ Advanced Security Features (Latest)

### ✅ Non-Privileged User Execution

**Implementation**: All containers now run as non-root users (UID/GID 1001)

**Benefits**:
- Prevents privilege escalation attacks
- Limits damage from container breakout
- Follows principle of least privilege

**Details**:
```yaml
# docker-compose.yml
user: "1001:1001"  # All application containers
```

```dockerfile
# Dockerfile
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup
USER appuser
```

### ✅ Read-Only Root Filesystem

**Implementation**: Root filesystem is mounted as read-only with tmpfs for writable directories

**Benefits**:
- Prevents malicious file modifications
- Blocks malware persistence
- Enforces immutable infrastructure

**Details**:
```yaml
read_only: true
tmpfs:
  - /tmp:uid=1001,gid=1001,mode=1770
  - /app/tmp:uid=1001,gid=1001,mode=1770
```

### ✅ No New Privileges Security Option

**Implementation**: `security_opt: [no-new-privileges:true]` on all containers

**Benefits**:
- Prevents privilege escalation via setuid/setgid
- Blocks sudo/su execution
- Mitigates container escape attempts

### ✅ Capability Dropping

**Implementation**: Drop all capabilities, add only required ones

**Benefits**:
- Minimal attack surface
- Prevents kernel exploits
- Follows least privilege

**Details**:
```yaml
cap_drop:
  - ALL
cap_add:
  - NET_BIND_SERVICE  # Only for services binding to ports
  - CHOWN             # Only for nginx
  - SETGID            # Only for postgres/redis
  - SETUID            # Only for postgres/redis
```

### ✅ Multi-Stage Docker Builds

**Implementation**: Separate build and production stages in Dockerfiles

**Benefits**:
- Smaller production images
- No build tools in production
- Reduced attack surface
- Faster deployments

**Image Sizes**:
- Backend: ~150MB (vs ~800MB without multi-stage)
- Frontend: ~25MB (vs ~600MB without multi-stage)

### ✅ Automated Security Scanning

**Implementation**:
- GitHub Actions workflow for automated scans
- Local `security-scan.sh` script
- Trivy for vulnerability detection
- Hadolint for Dockerfile linting
- Gitleaks for secret detection

**Scan Types**:
1. **Image Scanning**: Detects CVEs in dependencies
2. **Configuration Scanning**: Checks docker-compose.yml security
3. **Secret Scanning**: Finds exposed credentials
4. **Dockerfile Linting**: Best practices validation
5. **Dependency Auditing**: npm audit for packages

**Usage**:
```bash
# Local scan
./security-scan.sh

# Reports generated in: ./security-reports/

# CI/CD automatic scans on:
# - Every push to main/develop
# - Every pull request
# - Daily at 2 AM UTC
# - Manual trigger via workflow_dispatch
```

### ✅ Tmpfs Mounts

**Implementation**: Temporary filesystems for runtime data

**Benefits**:
- Faster I/O performance
- Data cleared on restart
- No persistent temp file exposure
- Memory-based storage

**Mounted Locations**:
- `/tmp` - General temporary files
- `/var/run` - PID files and sockets
- `/var/cache/nginx` - Nginx cache
- `/app/tmp` - Application temp files

### ✅ Docker Secrets (Enhanced)

**Implementation**: File-based secrets mounted at runtime

**Benefits**:
- Secrets never in environment variables
- Not visible in `docker inspect`
- Encrypted at rest (Docker Swarm)
- Proper access control

**Security Improvements**:
```yaml
# Before (INSECURE)
environment:
  DB_PASSWORD: "plaintext_password"

# After (SECURE)
secrets:
  - db_password
environment:
  DB_PASSWORD_FILE: /run/secrets/db_password
```

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

## 🔍 Security Scanning

### Automated CI/CD Scanning

The project includes automated security scanning via GitHub Actions (`.github/workflows/security-scan.yml`):

**Triggered On**:
- Push to main/develop branches
- Pull requests
- Daily at 2 AM UTC
- Manual workflow dispatch

**Scan Types**:
1. **Trivy Image Scanning** - CVE detection in Docker images
2. **Trivy Config Scanning** - docker-compose.yml security issues
3. **Dockerfile Linting** - Best practices with Hadolint
4. **Secret Detection** - Gitleaks for exposed credentials
5. **Dependency Auditing** - npm audit for vulnerable packages
6. **Docker Bench Security** - CIS benchmark compliance

**Results**: Available in GitHub Security tab (Code scanning alerts)

### Local Security Scanning

Run comprehensive security scans locally:

```bash
# Run full security scan
./security-scan.sh

# View results
ls -la security-reports/

# Check latest summary
cat security-reports/summary-*.txt
```

**The script will**:
1. Install Trivy if not present
2. Build Docker images
3. Scan images for vulnerabilities
4. Scan configuration files
5. Detect exposed secrets
6. Lint Dockerfiles
7. Generate detailed reports
8. Exit with error if CRITICAL vulnerabilities found

**Report Formats**:
- `backend-vulnerabilities-*.txt` - Human-readable backend scan
- `backend-vulnerabilities-*.json` - Machine-readable backend data
- `frontend-vulnerabilities-*.txt` - Human-readable frontend scan
- `frontend-vulnerabilities-*.json` - Machine-readable frontend data
- `config-scan-*.txt` - Configuration issues
- `secrets-scan-*.txt` - Exposed secrets
- `summary-*.txt` - Overall security summary

### Manual Trivy Scans

```bash
# Install Trivy
# macOS
brew install aquasecurity/trivy/trivy

# Ubuntu/Debian
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan specific image
trivy image gemini-mail-backend:latest

# Scan with specific severity
trivy image --severity CRITICAL,HIGH gemini-mail-backend:latest

# Scan configuration
trivy config .

# Scan for secrets
trivy fs --scanners secret .
```

### Snyk Integration (Optional)

For additional scanning with Snyk:

```bash
# Install Snyk CLI
npm install -g snyk

# Authenticate
snyk auth

# Test Docker images
snyk container test gemini-mail-backend:latest
snyk container test gemini-mail-frontend:latest

# Monitor images
snyk container monitor gemini-mail-backend:latest
snyk container monitor gemini-mail-frontend:latest

# Test dependencies
cd packages/backend && snyk test
cd packages/frontend && snyk test
```

### Handling Scan Results

**For CRITICAL vulnerabilities**:
1. **DO NOT DEPLOY** to production
2. Check for patches/updates
3. Update base images
4. Rebuild and rescan
5. If no fix available, consider mitigation strategies

**For HIGH vulnerabilities**:
1. Plan immediate remediation
2. Update dependencies
3. Rebuild images
4. Deploy fix in next release

**For MEDIUM/LOW vulnerabilities**:
1. Track in issue tracker
2. Plan remediation in upcoming sprint
3. Update during regular maintenance

### Vulnerability Remediation Process

```bash
# 1. Identify vulnerable package
trivy image --format json gemini-mail-backend:latest | jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL")'

# 2. Update package
# Edit package.json or Dockerfile

# 3. Rebuild image
npm run build:prod

# 4. Rescan
./security-scan.sh

# 5. Verify fix
trivy image gemini-mail-backend:latest

# 6. Deploy
npm run start:prod
```

## 📚 References

- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [Nginx Security](https://www.nginx.com/blog/nginx-security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

## 🐛 Reporting Security Issues

If you discover a security vulnerability, please email security@your-domain.com instead of using the issue tracker.
