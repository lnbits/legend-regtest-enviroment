FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Docker and Docker Compose
RUN curl -fsSL https://get.docker.com -o get-docker.sh && \
    sh get-docker.sh && \
    curl -L "https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Copy project files
WORKDIR /regtest
COPY . .

# Create data directory
RUN mkdir -p /regtest/data && chmod -R 777 /regtest

# Make scripts executable
RUN chmod +x start.sh docker-scripts.sh

# Configure Docker to use host's Docker daemon
ENV DOCKER_HOST=unix:///var/run/docker.sock

# Expose required ports
EXPOSE 5001 8081 10009 3001 3010

# Set a healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:5001 || exit 1

# Entry point script
COPY <<EOF /regtest/docker-entrypoint.sh
#!/bin/bash
set -e

# Check if Docker socket is available
if [ ! -S /var/run/docker.sock ]; then
  echo "ERROR: Docker socket not found at /var/run/docker.sock"
  echo "This container requires access to the host Docker daemon."
  echo "Please mount the Docker socket when running this container:"
  echo "docker run -v /var/run/docker.sock:/var/run/docker.sock ..."
  exit 1
fi

# Start regtest environment
bash ./start.sh

# Keep container running
tail -f /dev/null
EOF

RUN chmod +x /regtest/docker-entrypoint.sh

ENTRYPOINT ["/regtest/docker-entrypoint.sh"] 