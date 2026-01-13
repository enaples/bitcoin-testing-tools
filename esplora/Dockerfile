FROM node:18-alpine

# Clone Blockstream Esplora repository
RUN apk add --no-cache git bash curl && \
    git clone --depth 1 https://github.com/Blockstream/esplora.git /app && \
    apk del git

WORKDIR /app

# Set environment variables
ENV FLAVOR="bitcoin-signet"
ENV ELECTRS_BLOCKSTREAM_HOST="electrs-blockstream"
# Check the electrs-blockstream backend configuration on nginx side to verify the correct endpoint
ENV API_URL="http://localhost:8080"
ENV BASE_HREF="/"

# Install dependencies
RUN npm install

# Install serve globally for serving the built files
RUN npm install -g serve

# Make build script executable
RUN chmod +x build.sh

# Build the application
RUN npm run dist -- $FLAVOR

# Expose port
EXPOSE 8000

# Serve the built files
CMD ["serve", "dist", "-l", "8000", "-s"]
