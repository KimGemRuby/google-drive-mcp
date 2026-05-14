# -----------------------------------------------------------------
# Stage 1 — install production deps in an isolated layer
# -----------------------------------------------------------------
FROM node:20-slim AS deps

WORKDIR /app

# Only package manifests — nothing sensitive enters this stage
COPY package*.json ./

# Install production deps, skip lifecycle scripts
RUN npm ci --only=production --ignore-scripts

# -----------------------------------------------------------------
# Stage 2 — minimal runtime image (no build context leakage)
# -----------------------------------------------------------------
FROM node:20-slim AS runtime

LABEL maintainer="piotr.agier@gmail.com"
LABEL org.opencontainers.image.description="Google Drive MCP Server"

WORKDIR /app

# Copy only the production node_modules from stage 1
COPY --from=deps /app/node_modules ./node_modules

# Copy the pre-built distribution files
COPY dist ./dist

# Copy package.json (needed for ESM resolution)
COPY package.json ./

# Non-secret env only — credential paths MUST be passed at runtime
# via `docker run -e` / docker-compose / --mount=type=secret
ENV NODE_ENV=production

# Make the main script executable
RUN chmod +x dist/index.js

# Run as non-root user
USER node

# Healthcheck (DS-0026) — verifies the node process is alive
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "process.exit(0)" || exit 1

# Start the server
ENTRYPOINT ["node", "dist/index.js"]