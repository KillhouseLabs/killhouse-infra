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
      - grafana
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
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        tag: "web-client"
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
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        tag: "scanner-api"
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
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        tag: "exploit-agent"
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
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        tag: "sandbox"
    deploy:
      resources:
        limits:
          cpus: "0.50"
          memory: 2048M

  # =============================================================================
  # LGTM Monitoring Stack
  # =============================================================================

  grafana:
    image: grafana/grafana:11.4.0
    expose:
      - "3001"
    environment:
      GF_SERVER_HTTP_PORT: "3001"
      GF_SERVER_ROOT_URL: "https://${monitor_domain_name}/"
      GF_SECURITY_ADMIN_USER: admin
      GF_SECURITY_ADMIN_PASSWORD: "${grafana_admin_password}"
      GF_SMTP_ENABLED: "${smtp_user != "" ? "true" : "false"}"
      GF_SMTP_HOST: "smtp.gmail.com:587"
      GF_SMTP_USER: "${smtp_user}"
      GF_SMTP_PASSWORD: "${smtp_password}"
      GF_SMTP_FROM_ADDRESS: "${smtp_user != "" ? smtp_user : "noreply@killhouse.io"}"
      GF_SMTP_FROM_NAME: "Killhouse Monitoring"
      GF_ALERTING_ENABLED: "false"
      GF_UNIFIED_ALERTING_ENABLED: "true"
      GF_USERS_ALLOW_SIGN_UP: "false"
      GF_LOG_LEVEL: "warn"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./lgtm/grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    depends_on:
      - mimir
      - loki
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
    deploy:
      resources:
        limits:
          cpus: "0.15"
          memory: 192M

  loki:
    image: grafana/loki:3.5.0
    expose:
      - "3100"
    command: -config.file=/etc/loki/loki-config.yaml
    volumes:
      - ./lgtm/loki-config.yaml:/etc/loki/loki-config.yaml:ro
      - loki_data:/loki
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
    deploy:
      resources:
        limits:
          cpus: "0.20"
          memory: 256M

  mimir:
    image: grafana/mimir:2.16.0
    expose:
      - "9009"
    command:
      - -config.file=/etc/mimir/mimir-config.yaml
      - -server.http-listen-port=9009
    volumes:
      - ./lgtm/mimir-config.yaml:/etc/mimir/mimir-config.yaml:ro
      - mimir_data:/data
    restart: unless-stopped
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
    deploy:
      resources:
        limits:
          cpus: "0.20"
          memory: 256M

  alloy:
    image: grafana/alloy:v1.8.3
    expose:
      - "12345"
    command:
      - run
      - /etc/alloy/config.alloy
      - --server.http.listen-addr=0.0.0.0:12345
      - --stability.level=generally-available
    extra_hosts:
      - "host.docker.internal:host-gateway"
    pid: host
    volumes:
      - ./lgtm/alloy-config.alloy:/etc/alloy/config.alloy:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/log:/var/log/host:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/host/root:ro
      - alloy_data:/tmp/alloy
    restart: unless-stopped
    depends_on:
      - mimir
      - loki
    logging:
      driver: json-file
      options:
        max-size: "5m"
        max-file: "2"
    deploy:
      resources:
        limits:
          cpus: "0.15"
          memory: 128M

volumes:
  caddy_data:
  caddy_config:
  grafana_data:
  loki_data:
  mimir_data:
  alloy_data:
