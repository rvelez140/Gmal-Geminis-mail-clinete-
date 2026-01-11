#!/bin/bash

# Gemini Mail Enterprise - Secrets Setup Script
# This script generates secure random secrets for the application

set -e

echo "======================================"
echo "Gemini Mail Enterprise - Secrets Setup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if secrets directory exists
if [ ! -d "secrets" ]; then
    echo -e "${YELLOW}Creating secrets directory...${NC}"
    mkdir -p secrets
fi

# Function to generate a secret
generate_secret() {
    local file=$1
    local description=$2

    if [ -f "$file" ]; then
        echo -e "${YELLOW}⚠️  $file already exists. Skipping...${NC}"
        read -p "Do you want to regenerate it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    echo -e "${GREEN}Generating $description...${NC}"
    openssl rand -base64 32 > "$file"
    chmod 600 "$file"
    echo -e "${GREEN}✅ Created $file${NC}"
}

# Generate secrets
echo "Generating secure random secrets..."
echo ""

generate_secret "secrets/db_password.txt" "PostgreSQL password"
generate_secret "secrets/redis_password.txt" "Redis password"
generate_secret "secrets/jwt_secret.txt" "JWT secret key"

echo ""
echo -e "${GREEN}======================================"
echo "✅ Secrets generated successfully!"
echo "======================================${NC}"
echo ""

# Display secret info (first 8 chars only for security)
echo "Generated secrets (preview):"
for file in secrets/*.txt; do
    if [ -f "$file" ]; then
        preview=$(head -c 8 "$file")
        echo "  $(basename $file): ${preview}..."
    fi
done

echo ""
echo -e "${YELLOW}======================================"
echo "⚠️  SECURITY WARNINGS"
echo "======================================${NC}"
echo "1. These secrets are CRITICAL for security"
echo "2. NEVER commit secrets/ directory to git"
echo "3. Store a backup in a secure password manager"
echo "4. Use different secrets for each environment"
echo "5. Rotate secrets every 90 days"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}No .env file found.${NC}"
    read -p "Do you want to create one from .env.example? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env file. Please edit it with your values.${NC}"
    fi
fi

echo ""
echo -e "${GREEN}======================================"
echo "Next Steps:"
echo "======================================${NC}"
echo "1. Edit .env file with your configuration"
echo "2. Review SECURITY.md for deployment checklist"
echo "3. For development: npm run dev"
echo "4. For production: npm run start:prod"
echo ""
echo "For SSL/TLS setup (production), see nginx/ssl/README.md"
echo ""
