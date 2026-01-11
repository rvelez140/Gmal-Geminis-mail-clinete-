# Frontend Dockerfile - Gemini Mail Enterprise
# Multi-stage build for optimized production image

# Stage 1: Builder
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build application
RUN npm run build

# Stage 2: Production
FROM node:20-alpine AS production

# Install curl for healthcheck and dumb-init for signal handling
RUN apk add --no-cache curl dumb-init

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Install http-server globally
RUN npm install -g http-server && \
    npm cache clean --force

# Copy built application from builder
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check using curl (now installed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Start server with dumb-init for proper signal handling
CMD ["dumb-init", "http-server", "dist", "-p", "3000", "-c-1"]
