FROM node:18-alpine

# Clone Blockstream Esplora repository
RUN apk add --no-cache git bash curl && \
    git clone --depth 1 https://github.com/Blockstream/esplora.git /app && \
    apk del git

WORKDIR /app

# Set default environment variables
ENV FLAVOR="bitcoin-signet"
ENV BACKEND_PORT=8080
ENV PORT=9000
ENV BASE_HREF="/"

# Install dependencies
RUN npm install

# Install serve globally for serving the built files
RUN npm install -g serve

# Make build script executable
RUN chmod +x build.sh

# Don't build at image build time - build at container start time
# This allows runtime configuration of FLAVOR and API_URL

# Expose port
EXPOSE $PORT

# Build and serve at runtime with proper environment variables
CMD sh -c "API_URL=http://localhost:${BACKEND_PORT} npm run dist -- ${FLAVOR} && serve dist -l ${PORT} -s"
