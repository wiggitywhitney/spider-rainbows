# Multi-stage Dockerfile for Spider-Rainbows Demo App
# Stage 1: Build the React application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files and install ALL dependencies (including devDependencies for build)
COPY package*.json ./
RUN npm ci

# Copy source code and build the React app
COPY . .
RUN npm run build

# Stage 2: Production runtime
FROM node:20-alpine

WORKDIR /app

# Copy package files and install ONLY production dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy production server from source
COPY server.js ./

# Copy built React app from builder stage
COPY --from=builder /app/dist ./dist

# Expose port 8080 for both app and health endpoint
EXPOSE 8080

# Run the production server (single process per container)
# Handles both static React app serving and /health endpoint
CMD ["npm", "start"]
