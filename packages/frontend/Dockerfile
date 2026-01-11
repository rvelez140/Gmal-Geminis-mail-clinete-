# Frontend Dockerfile - Gemini Mail Enterprise
# Multi-stage build for optimized production image with cache optimization

# Stage 1: Builder
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files first (cache layer)
COPY package*.json ./

# Install dependencies (cache this layer)
RUN npm ci && \
    npm cache clean --force

# Copy source code (separate layer for better cache)
COPY . .

# Build application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production

# Install runtime dependencies in a single layer
# curl: required for healthcheck
# dumb-init: proper signal handling
RUN apk add --no-cache \
    curl \
    dumb-init \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Create non-root user early
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Install http-server globally for serving static files
RUN npm install -g http-server && \
    npm cache clean --force

# Copy built application from builder stage
# Only copy the dist folder, nothing else needed
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check using curl (lightweight check)
# Verifies the server is responding to HTTP requests
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start server with dumb-init for proper signal handling
# -p 3000: port
# -c-1: disable caching (development, remove for production)
CMD ["dumb-init", "http-server", "dist", "-p", "3000", "-c-1", "--cors"]
