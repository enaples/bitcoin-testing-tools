FROM node:18-alpine

# Clone Blockstream Esplora repository
RUN apk add --no-cache git bash curl && \
    git clone --depth 1 https://github.com/Blockstream/esplora.git /app && \
    apk del git

WORKDIR /app

# Set default environment variables
ENV FLAVOR="bitcoin-signet"
ENV PORT=8000
ENV BASE_HREF="/"

# Install dependencies
RUN npm install

# Install serve globally for serving the built files
RUN npm install -g serve

# Make build script executable
RUN chmod +x build.sh

# Expose port
EXPOSE $PORT

# Build and serve at runtime with proper environment variables.
# API_URL defaults to ${BASE_HREF}api (i.e. /api), a path the browser resolves
# against whatever host it reached the explorer on. nginx serves the explorer
# and the electrs API on the same origin, so this works from any network.
CMD sh -c "npm run dist -- ${FLAVOR} && serve dist -l ${PORT} -s"
