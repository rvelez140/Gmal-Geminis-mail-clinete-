#!/bin/bash

# ============================================================================
# Security Scanner Script for Gemini Mail Enterprise
# ============================================================================
# This script performs comprehensive security scanning on Docker images
# and configurations using Trivy and other security tools.
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TRIVY_SEVERITY="CRITICAL,HIGH,MEDIUM"
SCAN_DIR="./security-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create reports directory
mkdir -p "$SCAN_DIR"

echo -e "${BLUE}======================================"
echo "Security Scanner - Gemini Mail"
echo "======================================${NC}"
echo ""
echo "Timestamp: $TIMESTAMP"
echo "Reports directory: $SCAN_DIR"
echo ""

# ============================================================================
# Function: Check if Trivy is installed
# ============================================================================
check_trivy() {
    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}Trivy is not installed. Installing...${NC}"

        # Detect OS and install Trivy
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
            echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
            sudo apt-get update
            sudo apt-get install trivy -y
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install aquasecurity/trivy/trivy
        else
            echo -e "${RED}Unsupported OS. Please install Trivy manually.${NC}"
            exit 1
        fi
    fi
    echo -e "${GREEN}✓ Trivy is installed${NC}"
}

# ============================================================================
# Function: Build Docker images
# ============================================================================
build_images() {
    echo -e "${BLUE}Building Docker images...${NC}"

    if [ -d "packages/backend" ]; then
        echo "Building backend image..."
        docker build -t gemini-mail-backend:scan \
            --target production \
            ./packages/backend
    fi

    if [ -d "packages/frontend" ]; then
        echo "Building frontend image..."
        docker build -t gemini-mail-frontend:scan \
            --target production \
            ./packages/frontend
    fi

    echo -e "${GREEN}✓ Images built successfully${NC}"
    echo ""
}

# ============================================================================
# Function: Scan Docker images for vulnerabilities
# ============================================================================
scan_images() {
    echo -e "${BLUE}Scanning Docker images for vulnerabilities...${NC}"
    echo ""

    # Scan backend image
    if docker image inspect gemini-mail-backend:scan &> /dev/null; then
        echo "Scanning backend image..."
        trivy image \
            --severity "$TRIVY_SEVERITY" \
            --format table \
            --output "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.txt" \
            gemini-mail-backend:scan

        trivy image \
            --severity "$TRIVY_SEVERITY" \
            --format json \
            --output "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" \
            gemini-mail-backend:scan

        echo -e "${GREEN}✓ Backend scan complete${NC}"
    fi

    # Scan frontend image
    if docker image inspect gemini-mail-frontend:scan &> /dev/null; then
        echo "Scanning frontend image..."
        trivy image \
            --severity "$TRIVY_SEVERITY" \
            --format table \
            --output "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.txt" \
            gemini-mail-frontend:scan

        trivy image \
            --severity "$TRIVY_SEVERITY" \
            --format json \
            --output "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" \
            gemini-mail-frontend:scan

        echo -e "${GREEN}✓ Frontend scan complete${NC}"
    fi

    echo ""
}

# ============================================================================
# Function: Scan configuration files
# ============================================================================
scan_config() {
    echo -e "${BLUE}Scanning configuration files...${NC}"

    trivy config \
        --severity "$TRIVY_SEVERITY" \
        --format table \
        --output "$SCAN_DIR/config-scan-$TIMESTAMP.txt" \
        .

    trivy config \
        --severity "$TRIVY_SEVERITY" \
        --format json \
        --output "$SCAN_DIR/config-scan-$TIMESTAMP.json" \
        .

    echo -e "${GREEN}✓ Configuration scan complete${NC}"
    echo ""
}

# ============================================================================
# Function: Scan for secrets
# ============================================================================
scan_secrets() {
    echo -e "${BLUE}Scanning for exposed secrets...${NC}"

    trivy fs \
        --scanners secret \
        --format table \
        --output "$SCAN_DIR/secrets-scan-$TIMESTAMP.txt" \
        .

    echo -e "${GREEN}✓ Secrets scan complete${NC}"
    echo ""
}

# ============================================================================
# Function: Scan Dockerfiles
# ============================================================================
scan_dockerfiles() {
    echo -e "${BLUE}Linting Dockerfiles...${NC}"

    if command -v hadolint &> /dev/null; then
        for dockerfile in $(find . -name "Dockerfile" -o -name "Dockerfile.*"); do
            echo "Linting $dockerfile..."
            hadolint "$dockerfile" > "$SCAN_DIR/dockerfile-lint-$TIMESTAMP.txt" 2>&1 || true
        done
        echo -e "${GREEN}✓ Dockerfile linting complete${NC}"
    else
        echo -e "${YELLOW}⚠ hadolint not installed. Skipping Dockerfile linting.${NC}"
        echo "Install with: brew install hadolint (macOS) or see https://github.com/hadolint/hadolint"
    fi
    echo ""
}

# ============================================================================
# Function: Generate summary report
# ============================================================================
generate_summary() {
    echo -e "${BLUE}Generating summary report...${NC}"

    SUMMARY_FILE="$SCAN_DIR/summary-$TIMESTAMP.txt"

    cat > "$SUMMARY_FILE" << EOF
=================================================================
Security Scan Summary - Gemini Mail Enterprise
=================================================================
Scan Date: $(date)
Severity Levels: $TRIVY_SEVERITY

=================================================================
Scan Results
=================================================================

EOF

    # Count vulnerabilities in backend
    if [ -f "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" ]; then
        BACKEND_CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
        BACKEND_HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
        BACKEND_MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")

        cat >> "$SUMMARY_FILE" << EOF
Backend Image:
  CRITICAL: $BACKEND_CRITICAL
  HIGH:     $BACKEND_HIGH
  MEDIUM:   $BACKEND_MEDIUM

EOF
    fi

    # Count vulnerabilities in frontend
    if [ -f "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" ]; then
        FRONTEND_CRITICAL=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
        FRONTEND_HIGH=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
        FRONTEND_MEDIUM=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="MEDIUM")] | length' "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")

        cat >> "$SUMMARY_FILE" << EOF
Frontend Image:
  CRITICAL: $FRONTEND_CRITICAL
  HIGH:     $FRONTEND_HIGH
  MEDIUM:   $FRONTEND_MEDIUM

EOF
    fi

    cat >> "$SUMMARY_FILE" << EOF
=================================================================
Report Files
=================================================================

$(ls -1 "$SCAN_DIR"/*-$TIMESTAMP.* | sed 's/^/  - /')

=================================================================
Recommendations
=================================================================

1. Review all CRITICAL vulnerabilities immediately
2. Address HIGH vulnerabilities before production deployment
3. Plan remediation for MEDIUM vulnerabilities
4. Keep base images updated regularly
5. Re-run scans after applying fixes

=================================================================
EOF

    echo -e "${GREEN}✓ Summary report generated${NC}"
    echo ""
}

# ============================================================================
# Function: Display results
# ============================================================================
display_results() {
    echo -e "${BLUE}======================================"
    echo "Scan Complete!"
    echo "======================================${NC}"
    echo ""

    if [ -f "$SCAN_DIR/summary-$TIMESTAMP.txt" ]; then
        cat "$SCAN_DIR/summary-$TIMESTAMP.txt"
    fi

    echo ""
    echo -e "${GREEN}All reports saved to: $SCAN_DIR${NC}"
    echo ""

    # Check for critical vulnerabilities
    if [ -f "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" ] || [ -f "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" ]; then
        TOTAL_CRITICAL=0

        if [ -f "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" ]; then
            BACKEND_CRIT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$SCAN_DIR/backend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
            TOTAL_CRITICAL=$((TOTAL_CRITICAL + BACKEND_CRIT))
        fi

        if [ -f "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" ]; then
            FRONTEND_CRIT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$SCAN_DIR/frontend-vulnerabilities-$TIMESTAMP.json" 2>/dev/null || echo "0")
            TOTAL_CRITICAL=$((TOTAL_CRITICAL + FRONTEND_CRIT))
        fi

        if [ "$TOTAL_CRITICAL" -gt 0 ]; then
            echo -e "${RED}⚠ WARNING: $TOTAL_CRITICAL CRITICAL vulnerabilities found!${NC}"
            echo -e "${RED}⚠ Do NOT deploy to production until these are resolved.${NC}"
            exit 1
        else
            echo -e "${GREEN}✓ No CRITICAL vulnerabilities found${NC}"
        fi
    fi
}

# ============================================================================
# Main execution
# ============================================================================
main() {
    check_trivy
    build_images
    scan_images
    scan_config
    scan_secrets
    scan_dockerfiles
    generate_summary
    display_results
}

# Run main function
main
