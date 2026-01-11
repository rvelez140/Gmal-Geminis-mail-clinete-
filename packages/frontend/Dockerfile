# ============================================================================
# Frontend Dockerfile - Security Hardened
# ============================================================================
# Multi-stage build for minimal attack surface
# Non-privileged user execution
# Nginx serves static files as non-root
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

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy application code
COPY . .

# Build production bundle
RUN npm run build

# ============================================================================
# Production Stage - Nginx
# ============================================================================
FROM nginx:alpine AS production

# Install security updates and required tools
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    wget \
    && rm -rf /var/cache/apk/*

# Remove default nginx config and default user setup
RUN rm -rf /etc/nginx/conf.d/* /usr/share/nginx/html/*

# Create non-privileged user for nginx
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Create necessary directories with correct permissions
RUN mkdir -p /var/cache/nginx /var/log/nginx /var/run && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appgroup \
    /var/cache/nginx \
    /var/log/nginx \
    /var/run/nginx.pid \
    /usr/share/nginx/html \
    /etc/nginx/conf.d

# Copy nginx configuration
COPY --chown=appuser:appgroup nginx.conf /etc/nginx/nginx.conf

# Copy built application from builder
COPY --from=builder --chown=appuser:appgroup /build/dist /usr/share/nginx/html

# Create tmpfs mount points for runtime data
RUN mkdir -p /tmp/nginx && \
    chown -R appuser:appgroup /tmp/nginx

# Switch to non-privileged user
USER appuser

# Expose port (non-privileged port)
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start nginx in foreground
CMD ["nginx", "-g", "daemon off;"]

# ============================================================================
# Development Stage
# ============================================================================
FROM node:20-alpine AS development

# Install development tools and security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
    wget \
    git \
    && rm -rf /var/cache/apk/*

# Create non-privileged user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Create directories for development
RUN mkdir -p /app/node_modules && \
    chown -R appuser:appgroup /app

# Copy package files
COPY --chown=appuser:appgroup package*.json ./

# Switch to non-privileged user
USER appuser

# Install all dependencies (including dev)
RUN npm install && npm cache clean --force

# Switch back to root temporarily to ensure permissions
USER root
RUN chown -R appuser:appgroup /app

# Switch back to non-privileged user
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Development mode with hot-reload (Vite dev server)
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
