# Secrets Management

This directory contains sensitive credentials used by Docker services.

## ⚠️ SECURITY WARNING

- **NEVER** commit secret files to version control
- The `.gitignore` file should exclude this directory's contents
- Use strong, randomly generated secrets
- Rotate secrets regularly
- Restrict file permissions to prevent unauthorized access

## Required Secret Files

Create the following files with your secret values:

### 1. Database Password (`db_password.txt`)
```bash
echo "your-strong-database-password" > secrets/db_password.txt
chmod 600 secrets/db_password.txt
```

### 2. Redis Password (`redis_password.txt`)
```bash
echo "your-strong-redis-password" > secrets/redis_password.txt
chmod 600 secrets/redis_password.txt
```

### 3. JWT Secret (`jwt_secret.txt`)
```bash
echo "your-strong-jwt-secret-key" > secrets/jwt_secret.txt
chmod 600 secrets/jwt_secret.txt
```

## Generating Strong Secrets

Use one of these methods to generate cryptographically secure random secrets:

### Using OpenSSL (Recommended)
```bash
# Generate a 32-character base64 secret
openssl rand -base64 32

# Or a 64-character hex secret
openssl rand -hex 32
```

### Using Python
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Using Node.js
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

## Quick Setup Script

Create all secret files at once:

```bash
#!/bin/bash
# setup-secrets.sh

mkdir -p secrets

# Generate and save secrets
openssl rand -base64 32 > secrets/db_password.txt
openssl rand -base64 32 > secrets/redis_password.txt
openssl rand -base64 48 > secrets/jwt_secret.txt

# Set secure permissions
chmod 600 secrets/*.txt

echo "✅ Secrets generated successfully!"
echo "⚠️  Keep these files secure and never commit them to version control"
```

## File Permissions

Always set restrictive permissions on secret files:

```bash
# Owner read/write only
chmod 600 secrets/*.txt

# Verify permissions
ls -la secrets/
```

## Backup Recommendations

- Store secrets in a secure password manager
- Use encrypted backups
- Consider using external secret management solutions:
  - AWS Secrets Manager
  - HashiCorp Vault
  - Azure Key Vault
  - Google Cloud Secret Manager

## Production Best Practices

1. **Never use default or weak passwords**
2. **Use different secrets for each environment** (dev, staging, prod)
3. **Rotate secrets periodically** (every 90 days recommended)
4. **Use secret management tools** for production deployments
5. **Audit access to secrets**
6. **Use environment-specific secrets** - don't share between environments

## Troubleshooting

If services fail to start, check:

1. All required secret files exist
2. Files contain valid values (no extra whitespace/newlines)
3. File permissions are correct (600)
4. Files are readable by Docker daemon

## Docker Secrets Alternative

For Docker Swarm mode, consider using Docker's native secrets:

```bash
echo "password" | docker secret create db_password -
docker secret ls
```

Then update `docker-compose.yml` to use external secrets:

```yaml
secrets:
  db_password:
    external: true
```
