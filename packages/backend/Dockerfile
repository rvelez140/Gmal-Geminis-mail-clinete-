# ============================================================================
# Backend Dockerfile - Security Hardened
# ============================================================================
# Multi-stage build for minimal attack surface
# Non-privileged user execution
# Read-only root filesystem compatible
# Optimized caching for faster builds
# ============================================================================

# Build Stage
FROM node:20-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    && rm -rf /var/cache/apk/*

WORKDIR /build

# Copy package files (leverages Docker cache)
COPY package*.json ./
COPY tsconfig*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY . .

# Build application (if using TypeScript)
RUN if [ -f "tsconfig.json" ]; then npm run build; fi

# ============================================================================
# Production Stage
# ============================================================================
FROM node:20-alpine AS production

# Install security updates and required runtime tools
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    wget \
    dumb-init \
    && rm -rf /var/cache/apk/*

# Create non-privileged user and group
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Create necessary directories with correct permissions
RUN mkdir -p /app/logs /app/tmp /app/uploads && \
    chown -R appuser:appgroup /app

# Copy application from builder
COPY --from=builder --chown=appuser:appgroup /build/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /build/package*.json ./

# Copy built application or source code
COPY --chown=appuser:appgroup . .

# If dist directory exists from build, ensure permissions
RUN if [ -d "dist" ]; then chown -R appuser:appgroup dist; fi

# Switch to non-privileged user
USER appuser

# Expose port (app should listen on this)
EXPOSE 8000

# Health check - use wget for Alpine compatibility
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8000/api/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start application
CMD ["node", "server.js"]

# ============================================================================
# Development Stage
# ============================================================================
FROM node:20-alpine AS development

# Install development tools and security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    wget \
    dumb-init \
    git \
    && rm -rf /var/cache/apk/*

# Create non-privileged user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Create directories for development
RUN mkdir -p /app/logs /app/tmp /app/uploads /app/node_modules && \
    chown -R appuser:appgroup /app

# Copy package files
COPY --chown=appuser:appgroup package*.json ./

# Switch to non-privileged user for npm install
USER appuser

# Install all dependencies (including dev)
RUN npm install && npm cache clean --force

# Switch back to root temporarily to set up volume permissions
USER root
RUN chown -R appuser:appgroup /app

# Switch back to non-privileged user
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8000/api/health || exit 1

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Development mode with hot-reload
CMD ["npm", "run", "dev"]
