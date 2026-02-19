services:
  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped
    depends_on:
      - web-client
      - scanner-api
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 256M

  web-client:
    image: ${ecr_registry_url}/killhouse/web-client:latest
    expose:
      - "3000"
    env_file:
      - .env
    environment:
      NODE_ENV: production
      PORT: "3000"
      SCANNER_API_URL: "http://scanner-api:8080"
      SANDBOX_API_URL: "http://sandbox:8000"
      ANALYSIS_API_URL: "http://exploit-agent:8001"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 1536M

  scanner-api:
    image: ${ecr_registry_url}/killhouse/scanner-api:latest
    expose:
      - "8080"
    env_file:
      - .env
    environment:
      ENVIRONMENT: ${environment}
      PORT: "8080"
      EXPLOIT_AGENT_URL: "http://exploit-agent:8001"
      CONTAINER_RUNTIME: docker
      CORS_ALLOWED_ORIGINS: "https://${domain_name}"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 1536M

  exploit-agent:
    image: ${ecr_registry_url}/killhouse/exploit-agent:latest
    expose:
      - "8001"
    env_file:
      - .env
    environment:
      SANDBOX_API_URL: "http://sandbox:8000"
      DATABASE_URL: "sqlite+aiosqlite:///./sessions.db"
      CORS_ALLOWED_ORIGINS: "https://${domain_name}"
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.25"
          memory: 1024M

  sandbox:
    image: ${ecr_registry_url}/killhouse/exploit-sandbox:latest
    expose:
      - "8000"
    env_file:
      - .env
    environment:
      CORS_ALLOWED_ORIGINS: "https://${domain_name}"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 2048M

volumes:
  caddy_data:
  caddy_config:
