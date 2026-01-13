FROM node:18-alpine

# Clone Blockstream Esplora repository
RUN apk add --no-cache git bash curl && \
    git clone --depth 1 https://github.com/Blockstream/esplora.git /app && \
    apk del git

WORKDIR /app

# Install dependencies
RUN npm install

# Install serve globally for serving the built files
RUN npm install -g serve

# Make build script executable
RUN chmod +x build.sh

# Build the application with the API URL
# IMPORTANT: This should point to where YOUR BROWSER can reach the API
# So, expose the nginx port (in this case 8080) related to the electrs-blockstream configuration
ARG API_URL=http://localhost:8080/api

RUN npm run dist

# Expose port
EXPOSE 8000

# Serve the built files
CMD ["serve", "dist", "-l", "8000", "-s"]
