${domain_name} {
    tls ${acme_email}

    header {
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=()"
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        -Server
    }

    reverse_proxy web-client:3000

    handle_path /scanner/* {
        reverse_proxy scanner-api:8080
    }
    handle /scanner {
        reverse_proxy scanner-api:8080
    }
}

${monitor_domain_name} {
    tls ${acme_email}

    header {
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        -Server
    }

    reverse_proxy grafana:3001
}
