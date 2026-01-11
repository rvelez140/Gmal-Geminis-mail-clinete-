# Backend Dockerfile - Gemini Mail Enterprise
# Multi-stage build for optimized production image with cache optimization

# Stage 1: Base image with system dependencies
FROM node:20-alpine AS base

# Install system dependencies in a single layer
RUN apk add --no-cache \
    dumb-init \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Stage 2: Dependencies (leverages Docker cache)
FROM base AS dependencies

# Copy only package files first (cache layer)
COPY package*.json ./

# Install production dependencies in a separate layer
RUN npm ci --only=production && \
    npm cache clean --force

# Store production node_modules
RUN cp -R node_modules /tmp/node_modules_prod

# Install all dependencies (including dev for potential build steps)
RUN npm ci && \
    npm cache clean --force

# Stage 3: Production image
FROM base AS production

# Create non-root user early
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production dependencies from dependencies stage
COPY --from=dependencies --chown=nodejs:nodejs /tmp/node_modules_prod ./node_modules

# Copy package files
COPY --chown=nodejs:nodejs package*.json ./

# Copy application code
COPY --chown=nodejs:nodejs . .

# Create logs directory with proper permissions
RUN mkdir -p logs && \
    chown -R nodejs:nodejs logs

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 8000

# Health check using Node.js (no external dependencies)
# Lightweight check that doesn't require curl/wget
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8000/api/health', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Start application with dumb-init for proper signal handling
# dumb-init handles signals properly and reaps zombie processes
CMD ["dumb-init", "node", "src/server.js"]
