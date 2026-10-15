# Caddy custom build with xcaddy
ARG CADDY_VERSION=2.11.4

FROM caddy:${CADDY_VERSION}-builder AS builder
ARG CADDY_VERSION
ARG PLUGIN_CLOUDFLARE=v0.2.4
ARG PLUGIN_DESEC=v1.1.0
ARG PLUGIN_CLOUDFLARE_IP=f53b62aa13cb7ad79c8b47aacc3f2f03989b67e5
ARG PLUGIN_COMBINE_IP_RANGES=5624d08f5f9e788816bdd877b7c81280c69b434e
ARG PLUGIN_WEBDAV=fa2f366b0d75e54c2e381c0aefc3a8df8bf5794b

RUN xcaddy build \
    "v${CADDY_VERSION}" \
    --with github.com/caddy-dns/cloudflare@${PLUGIN_CLOUDFLARE} \
    --with github.com/caddy-dns/desec@${PLUGIN_DESEC} \
    --with github.com/WeidiDeng/caddy-cloudflare-ip@${PLUGIN_CLOUDFLARE_IP} \
    --with github.com/fvbommel/caddy-combine-ip-ranges@${PLUGIN_COMBINE_IP_RANGES} \
    --with github.com/mholt/caddy-webdav@${PLUGIN_WEBDAV}

FROM caddy:${CADDY_VERSION}-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
ENTRYPOINT ["caddy"]
CMD ["version"]
