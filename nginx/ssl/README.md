# SSL Certificates

Place your SSL certificates in this directory for HTTPS support.

## Required Files

- `cert.pem` - SSL certificate
- `key.pem` - Private key
- `chain.pem` - Certificate chain (optional)

## Generating Self-Signed Certificates (Development Only)

For development purposes, you can generate self-signed certificates:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

## Production Certificates

For production, use certificates from a trusted Certificate Authority (CA):

- Let's Encrypt (free): Use certbot to obtain certificates
- Commercial CA: Purchase from providers like DigiCert, GlobalSign, etc.

## Security Notes

- **NEVER** commit private keys to version control
- Keep private keys secure with appropriate file permissions (600)
- Rotate certificates before expiration
- Use strong key sizes (minimum 2048-bit RSA)

## File Permissions

```bash
chmod 600 nginx/ssl/key.pem
chmod 644 nginx/ssl/cert.pem
```
