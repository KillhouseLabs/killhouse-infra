${domain_name} {
    tls ${acme_email}

    reverse_proxy web-client:3000

    handle_path /scanner/* {
        reverse_proxy scanner-api:8080
    }
    handle /scanner {
        reverse_proxy scanner-api:8080
    }
}
