# Use Node.js LTS as base image
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only, skipping lifecycle scripts
RUN npm ci --only=production --ignore-scripts

# Copy built distribution files
COPY dist ./dist

# Create directory for config files
RUN mkdir -p /config

# Set environment variables (credential paths must be passed at runtime via -e or docker-compose)
ENV NODE_ENV=production

# Make the main script executable
RUN chmod +x dist/index.js

# Run as non-root user
USER node

# Start the server
ENTRYPOINT ["node", "dist/index.js"]